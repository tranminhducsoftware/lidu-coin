pragma solidity >= 0.7.0 <= 0.8.1;
import './DoMath.sol';

contract LiduCoin
{
    using DoMath for uint;

    // variable
     mapping(address => uint) public balances;
     string constant symbol  = "LIDUCOIN";
     uint8 constant decimals =  6;
     address public owner;
     address public perons;
     
     //event
     event MintCoin(address _receiver, uint _amount_wei); // số lượng tính bằng wei
     event MoneySent(address _sender, address _receiver, uint _amount_wei); // số lượng tính bằng wei
     event TransferEthFromBrrower(address _sender, uint _amount_wei); // số lượng tính bằng wei
      
     // modifier
     modifier onlyOwner(){
         require(msg.sender == owner, 'Only owner can call');
         _;
     }
     
     //constructor
     constructor() {
         owner = msg.sender;
     }
     
    // function
    // mint coin cho người nhận(_receiver) với số tiền _amount
     function mint( address _receiver, uint _amount) public onlyOwner {
        uint amount_wei = _amount * 10**decimals;
        balances[_receiver] =  balances[_receiver].add(amount_wei);
        emit MintCoin( _receiver, amount_wei);
     }
     
     // Xem số dư của địa chỉ (_address)
     function getBalanceOf(address _address) public view returns(uint){
         return balances[_address];
     }
     
     
     // hàm chuyển coin
    function _transfer(address _sender, address _receiver, uint _amount) private returns(bool){
        require(getBalanceOf(_sender) >= _amount , 'Insufficient funds');
        balances[_sender]= balances[_sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        
        emit MoneySent(_sender, _receiver, _amount );
        return true;
            
    }
    
    // hàm send coin
    function send(address _receiver, uint _amount) public {
        address sender = msg.sender;
           _transfer(sender, _receiver,_amount *10**decimals);
    }
    
    // chủ coin là sàn giao dịch luôn
    // hàm gửi tiền cọc tạo một khoản vay
    function transferFromLender(address _sender, uint256 _amount) public {
        address receiver = owner;
          _transfer(_sender, receiver, _amount);
    }
    
    
    function transferToBrrower(address _receiver, uint256 _amount) public returns(bool) {
        address sender = owner;
        return  _transfer(sender, _receiver, _amount);
    }
    
     // hàm chuyển số eth còn lại
     function transferEthFromBrrower(address _sender, uint _amount) public payable  {
         payable(_sender).transfer(_amount);
         emit TransferEthFromBrrower(_sender, _amount);
     }
     
     // hàm xem số eth còn lại
     function getBalanceEth(address _address) public view returns (uint256) {
         return address(_address).balance ;
     }
     
     function transferp2p(address _lender, address _brrower, uint _amount, uint _eth_wei) public {
          _transfer(_brrower, owner, _amount);
        //   transferEthFromBrrower(owner,_eth_wei);
          _transfer(owner, _lender, _amount);
     }
     
   
    
    

     /////////////////////////////////////// P2PLending
    struct Person {
        address _address; // địa chỉ người cho vay
        string name; // Tên người cho vay
    }
    
    struct Loan {
        address borrower;
        address lender;
        uint interest_rate; // lãi xuất theo ngày
        uint duration; // thời hạn tính bằng giây
        uint eth_guarantee; // số eth đảm bảo
        uint principal_amount; // tiền gốc 
        uint interest_amount; // tiền lãi
        uint start_time;
        uint start_time_loan;
        uint end_load;
        bool is_exsit; // tồn tại khoản vay trên hệ thống nếu bằng false người cho vay đã huỷ 
        bool are_lending; // đang cho vay
    }
    
    mapping(uint => Loan) public loads;
    uint public _load_id;
    uint8 constant decimals18 =  18;

    event LoadCreated(uint _id);
    event DoLoan(uint _id, uint _amount, uint _duration, uint _interest_rate, uint  _eth_wei_guarantee,address _lender , address _brrower);
    event Repay(uint _id);
    
     // tính toán số lượng cần đặt cọc
    function calculateGuaranteedEth(uint _amount, uint _LTV_rate) private pure returns (uint){
        uint wei_guarantee = (_amount * 10**decimals18 ) / _LTV_rate;
        return wei_guarantee;
    }
    
    // lender tạo một yêu cầu cho vay
    function createALoad(uint _amount, uint _LTV_rate, uint _duration , uint _interest_rate) public {
        require(_amount > 0 ,'Amount is greater than 0');
        
        uint wei_guarantee = calculateGuaranteedEth(_amount, _LTV_rate);
        address lender = msg.sender;
        
        uint amount_lender =  getBalanceOf(lender);
        uint amount_wei = _amount * 10**decimals;
        require(amount_lender >= amount_wei ,'Insufficient funds');
         transferFromLender(lender, amount_wei);
         uint _id = _load_id ++;
        loads[_id] = Loan({
            lender : lender,
            borrower : lender,
            principal_amount :_amount,
            start_time : block.timestamp,
            duration: _duration,
            interest_rate : _interest_rate,
            start_time_loan : 0,
            end_load: 0,
            interest_amount : 0,
            eth_guarantee : wei_guarantee,
            is_exsit : false,
            are_lending : false
        });
        emit LoadCreated(_id);
    }
    
    // brrower tiến hành vay
    function doLoad(uint _id) public returns(bool){
        bool are_lending =  loads[_id].are_lending;
        require(are_lending == false, 'This loan has been borrowed');
        
        address borrower = msg.sender;
        uint eth_guarantee = loads[_id].eth_guarantee;
        uint amount_eth =  getBalanceEth(borrower);
        require(amount_eth >=eth_guarantee, 'Not enough guaranteed eth');
        // chuyển eth
        // transferEthFromBrrower(borrower,100);
     
        bool is_transfer_success = transferToBrrower(borrower, uint(loads[_id].principal_amount *10**decimals) );
        require(is_transfer_success == true ,'Coin transfer failed');

        loads[_id].are_lending = true;
        loads[_id].borrower = borrower;
        loads[_id].end_load =  block.timestamp.add(loads[_id].duration * 1 minutes) ;
        loads[_id].start_time_loan =  block.timestamp;

        emit DoLoan(_id,
                    loads[_id].principal_amount,
                    loads[_id].duration,
                    loads[_id].interest_rate,
                    loads[_id].eth_guarantee,
                    loads[_id].lender,
                    loads[_id].borrower
                   );
        return true;
    }
    
    // xem thời gian hiện tại
    function viewTimeNow() public view returns(uint) { 
        return  block.timestamp;
    }
    
    // số phút đã qua từ khi brrower vay . số phút tính lãi
    function passedMinutesAdd(uint _time_start) public view returns(uint){
        uint time_now = viewTimeNow();
        
        uint seconds_range = time_now.sub(_time_start); 
        uint time_minutes = (seconds_range/ 60) + 1;
        return time_minutes;
        
    }
    
    // kiểm tra thời gian đã hết hạn chưa
    function checkExpirationTime(uint _end_time) public view returns(uint){
        uint time_now =  viewTimeNow();
        if( (time_now) > _end_time + 60) return 0;
        uint time_expirate = (_end_time.add(60)).sub(time_now);
        return time_expirate;
    }
    
    // xem tiền lãi tính tới thời điểm hiện tại
    function viewInterestCurent(uint _id) public view returns(uint){
         uint id = _id;
         uint passed_minutes = passedMinutesAdd(loads[_id].start_time_loan); // check xem đã qua bao nhiêu phút
         uint time_expirate = checkExpirationTime(loads[id].end_load); // check thời gian đã hết chưa
         require(loads[id].are_lending ==true,'No borrowers');
         require(time_expirate > 0,'Interest payment time has passed');
         
         uint interest = ((loads[id].principal_amount * 10**decimals) * loads[id].interest_rate * passed_minutes)/100;
         return interest;
    }
    

    // xem thông tin yêu cầu cho vay
    function getLoan(uint _id) public view returns(address,address,uint,uint,uint,uint,uint,uint,uint,bool,bool, bool){   
        uint id = _id;
        uint time_expirate = checkExpirationTime(loads[id].end_load); // check thời gian đã hết chưa
        bool is_end = false;
        if(time_expirate ==0){
           is_end = true; 
        }
        uint  view_interest_curent = 0;
        if(loads[id].are_lending == true){
            view_interest_curent = viewInterestCurent(id);
        }

        return (
        loads[id].lender,
        loads[id].borrower,
        loads[id].principal_amount,
        loads[id].start_time,
        loads[id].duration,
        loads[id].end_load,
        view_interest_curent,
        loads[id].eth_guarantee,
        loads[id].interest_rate,
        loads[id].is_exsit,
        loads[id].are_lending,
        is_end
        );
    }
    

    function repay(uint _id) public {
        uint id = _id;
         uint time_expirate = checkExpirationTime(loads[id].end_load); // check thời gian đã hết chưa
         require(time_expirate > 0,'Interest payment time has passed');
         uint amount_interest =  ((loads[id].principal_amount * 10**decimals) * loads[id].interest_rate *  loads[id].duration)/100;
         uint payment = (loads[id].principal_amount * 10**decimals).add(amount_interest);
         //trả trước
         if(time_expirate>60){
             uint amount_percent_five = (( loads[id].principal_amount *10**decimals )* 5)/100;
             payment = payment.add(amount_percent_five);
         }
         
        address brrowe = msg.sender;
        address lender = loads[id].lender;
        uint amount_brrower =  getBalanceOf(brrowe);
        require(amount_brrower >=payment, 'Insufficient funds');
        loads[id].is_exsit = true;
        transferp2p(lender, brrowe, payment,loads[id].eth_guarantee);
        emit Repay(id);
    }
     
     
     
     
}