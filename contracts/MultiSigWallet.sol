// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public reuqired;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(transactions.length < _txId, "tx does not exist");
        _;
    }
    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }
    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint required){
        require(_owners.length > 0, "owners required");
        require(
            required > 0 && required <= owners.length,
            "invalid required number of owners"
        );
        for(uint i; i < owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata data) 
        external
        onlyOwner
    {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) 
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }
}