pragma solidity ^0.4.6;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ErrorLogger.sol";

contract MngWallet is Ownable, ErrorLogger, ERC20 {

    // A BICCC code uniquely identifies a bank on the blockchain.
    // The value is composed of the BIC code of the bank and the currency
    // code of the token.
    bytes14 public biccc;
    // Currency code (ISO-4217) of the backed money.
    bytes3 public currencyCode;

    address public ownerOri;


    // Internal struct representing an wallet in the bank.
    struct WalletSt {
        // The wallet ballance. Can be negative.
        int256 balance;
        // To check if the struct exists in the mapping.
        bool exists;
    }

    // Wallets mapping owner => wallets
    mapping(address => WalletSt) public wallets;


    // Total supply can be negative
    int256 public sumBalances;  // El dinero que maneja el gestor que indica el traspaso de dinero total entre el banco y las diferentes cuentas

    // Mapping wallet => redeemer => true if allowed
    mapping (address => mapping (address => bool)) public allowedTransferFunds;

    // Constructor.
    function MngWallet(bytes14 _biccc, bytes3 _currencyCode) {
        sumBalances = 0;
        biccc = _biccc;
        currencyCode = _currencyCode;
        ownerOri = msg.sender;
    }

    // Wallet creation

    // Opens wallet for msg.sender if it doesn't have an existing one.
    // Variación !!!  : la cuenta master abre los wallets
 
    function openWallet(address _walletOwner ) onlyOwner returns (bool success) {
        if(walletExists(_walletOwner)){
            LogError(1000,'wallet exists');
            return false;
        }
        wallets[_walletOwner] = WalletSt(0, true);
        Ev_WalletOpened(_walletOwner);
        return true;
    }

    // Checks if there exists a wallet at the specified address.
    function walletExists(address _walletOwner) constant returns (bool exists) {
        return wallets[_walletOwner].exists;
    }

    // Transfer permissions

    // Approves _transferer to transfer funds on behalf of msg.sender.
    function approveTransferFunds(address _transferer) returns (bool success){
        allowedTransferFunds[msg.sender][_transferer] = true;
        Ev_ApprovalTransferFunds(msg.sender, _transferer);
        return true;
    }

    // Revokes _transferer rights to transfer on behalf of msg.sender.
    function RevokeTransferFunds(address _transferer) returns (bool success){
        allowedTransferFunds[msg.sender][_transferer] = false;
        Ev_RevokeTransferFunds(msg.sender, _transferer);
        return true;
    }

    // Adds funds to the balance of the given wallet.
    // The reference is only used in the emitted event.
    // It is only done if the sender is the origin of the contract (no, any msg.sender)
    // This wallet receive money. The wallet earns money

    // El gestor de las cuentas pasa el dinero tokenizado al wallet()
    function addFunds(address _wallet, uint256 _amount, string _reference) onlyOwnerOrigin returns (bool success) {
        if (!walletExists(_wallet)) {
            LogError(2000,'wallet does not exist');
            return false;
        }
        wallets[_wallet].balance += int256(_amount);
        sumBalances += int256(_amount);
        Ev_FundsAdded(_wallet,_amount,_reference);
        return true;
    }

    // Redeems funds from the balance of the given wallet.
    // It is only done if the sender is the origin of the contract (no, any msg.sender)
    // This wallet pays. The wallet loses money 
    
    // El gestor de las cuentas pasa el dinero tokenizado del wallet() a la cuenta real.. se destokeniza
    
    function redeemFunds(address _wallet, uint256 _amount) onlyOwnerOrigin returns (bool success) {
        if (!walletExists(_wallet)){
            LogError(2000,'wallet does not exist');
            return false;
        }
        if (wallets[_wallet].balance < int256(_amount)) {
            LogError(2003,'not enough balance');
            return false;
        }
        wallets[_wallet].balance -= int256(_amount);
        sumBalances -= int256(_amount);
        Ev_FundsRedeemed(_wallet, _amount);
        return true;
    }

/////////////////////////////////////////////////////////////////////////////////////
//
//     GESTION DE SOLICITUDES DE DINERO A RETIRAR
//
/////////////////////////////////////////////////////////////////////////////////////
    // Holds a request by a wallet to have it's funds withdrawn.
    // Gestiona solicitud para retirar fondos
    struct WithdrawalRequestSt {
        address wallet;
        uint256 amount;
        uint256 expiration;
    }

    // All the outstanding withdrawals.
    // Las solicitudes de retiro de dinero pendientes
    mapping(uint256 => WithdrawalRequestSt) public withdrawals;
    uint256 public lastWithdrawalIndex;
    // The time after which a withdrawal request expires. Currently 24 hours.
    uint256 constant withdrawalExpirationTime = 24 * 60 * 60;  // 24 horas en segundos

    // Requests a withdrawal for the wallet of the caller and returns the
    // withdrawal index that is needed to accept or expire withdrawals.
    // Emits a Ev_WithdrawalRequested event on success.
    function requestWithdrawal(uint256 _amount) returns (uint256 withdrawalIndex) {
        address wallet = msg.sender;
        if (!walletExists(wallet)){
            LogError(2000,'wallet does not exist');
            return 0;
        }
        if (wallets[wallet].balance < int256(_amount)) {
            LogError(2003,'not enough balance');
            return 0;
        }

        // Take the money out of the account.
        wallets[wallet].balance -= int256(_amount);

        // Create the withdrawal object and store it.
        uint256 index = lastWithdrawalIndex + 1;
        uint256 expiration = now + withdrawalExpirationTime;
        withdrawals[index] = WithdrawalRequestSt(wallet, _amount, expiration);
        lastWithdrawalIndex = index;
        Ev_WithdrawalRequested(index, wallet, _amount);
    }

    // Accept the withdrawal. Can only be called by the owner.
    // This method will remove the withdrawal and subtract the amount from
    // the total supply. If the withdrawal is expired at the time of calling,
    // this method will have the same effect as `expireWithdrawal()`.
    // Emits a Ev_WithdrawalAccepted event on success.
    function acceptWithdrawal(uint256 _withdrawalIndex) onlyOwner returns (bool success) {
        WithdrawalRequestSt withdrawal = withdrawals[_withdrawalIndex];
        if (withdrawal.wallet == 0) {
            // Withdrawal does not exist.
            LogError(2004, "withdrawal does not exist");
            return false;
        }
        if (now >= withdrawal.expiration) {
            refundAndRemoveExpiredWithdrawal(_withdrawalIndex);
            LogError(2005, "withdrawal expired");
            return false;
        }
        // Only now the total supply is changed.
        sumBalances -= int256(withdrawal.amount);
        Ev_WithdrawalAccepted(_withdrawalIndex, withdrawal.wallet, withdrawal.amount);
        delete(withdrawals[_withdrawalIndex]);
        return true;
    }

    // Removes the withdrawal and refunds the money to the owner.
    // This method assumes that a withdrawal with the given index exists.
    function refundAndRemoveExpiredWithdrawal(uint256 _index) private {
        WithdrawalRequestSt withdrawal = withdrawals[_index];
        // Refund the money.
        wallets[withdrawal.wallet].balance += int256(withdrawal.amount);
        Ev_WithdrawalExpired(_index, withdrawal.wallet, withdrawal.amount);
        delete(withdrawals[_index]);
    }

    // Expires a withdrawal and refunds the amount to the wallet.
    // This method has no effect before the expiration time.
    // Emits a WithdrawalExpired event on success.
    function expireWithdrawal(uint256 _withdrawalIndex) returns (bool success) {
        WithdrawalRequestSt req = withdrawals[_withdrawalIndex];
        if (req.wallet == 0) {
            // Withdrawal does not exist.
            LogError(2004, "withdrawal does not exist");
            return false;
        }
        if (now < req.expiration) {
            LogError(2006, "withdrawal not yet expired");
            return false;
        }
        refundAndRemoveExpiredWithdrawal(_withdrawalIndex);
        return true;
    }

    // Returns the total amount of money the wallet has available. This is
    // equal to the balance of that wallet.
    function availableFunds(address _wallet) constant returns (uint256 funds) {
        WalletSt wallet = wallets[_wallet];
        return uint256(wallet.balance);
    }

    /* ERC20 token standard functions */

    // Transfers funds from msg.sender to _to.
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (wallets[msg.sender].balance < int256(_value)) {
            LogError(3001, 'not enough balance');
            return false;
        }
        wallets[msg.sender].balance -= int256(_value);
        wallets[_to].balance += int256(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // Transfers funds from _from to _to if msg.sender is allowed.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_from != msg.sender && !allowedTransferFunds[_from][msg.sender]) {
            LogError(3000, 'msg.sender cannot transfer from this wallet');
            return false;
        }
        if (wallets[_from].balance < int256(_value)) {
            LogError(3001, 'not enough balance');
            return false;
        }
        wallets[_from].balance -= int256(_value);
        wallets[_to].balance += int256(_value);
        Transfer(_from, _to, _value);
        return true;
    }

      
    function kill() onlyOwner {
        selfdestruct(owner);
    }   


    // Total supply of tokens in the contract.
    // To be compatible with ERC20 we return 0 in case
    // of negative balance.
    function totalSupply() constant returns (uint256 supply){
        if (sumBalances < 0) return 0;
        else return uint256(sumBalances);
    }

    // Returns the balance of the wallet.
    // To be compatible with ERC20 we return 0 in case
    // of negative balance.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (wallets[_owner].balance < 0) return 0;
        return uint256(wallets[_owner].balance);
    }

    // TODO: implement
    function approve(address _spender, uint256 _value) returns (bool success) {
        throw;
    }
    // TODO: implement
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        throw;
    }


    function() {
        throw;
    }

    //EVENTS
    // Triggered when openWallet succeeds.
    event Ev_WalletOpened(address indexed wallet);
    // Triggered when a wallet approves a transferer.
    event Ev_ApprovalTransferFunds(address indexed _owner, address indexed _transferer);
    // Triggered when a wallet revokes a transferer.
    event Ev_RevokeTransferFunds(address indexed _owner, address indexed _transferer);
    // Triggered when funds are added to a wallet.
    event Ev_FundsAdded(address indexed _wallet, uint256 indexed _amount, string _reference);
    // Triggered when funds are redeemed.
    event Ev_FundsRedeemed(address indexed _wallet, uint256 indexed _amount);
    // Triggered when a user requests a new withdrawal.
    event Ev_WithdrawalRequested(uint256 indexed _index, address indexed _wallet, uint256 _amount);
    // Triggered when the bank accepts a withdrawal request.
    event Ev_WithdrawalAccepted(uint256 indexed _index, address indexed _wallet, uint256 _amount);
    // Triggered when a withdrawal request has expired.
    event Ev_WithdrawalExpired(uint256 indexed _index, address indexed _wallet, uint256 _amount);
}