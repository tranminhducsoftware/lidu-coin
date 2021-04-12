pragma solidity >= 0.7.0 <= 0.8.1;

library DoMath {
    function add(uint a, uint b) public pure returns (uint){
        uint c = a+b;
        require(c >= a, 'Over flow: add');
        return c;
    }

    function sub(uint a, uint b) public pure returns (uint){
        require(a > b , 'Over flow: sub');
        return a-b;
    }

}
