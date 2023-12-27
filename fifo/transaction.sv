
///////// TRANSACTION CLASS ////////
class transaction;
 rand bit op;     // Randomized bit for operation control (1 or 0)
 rand bit [7:0] data_in; // 8-bit data input
 bit [7:0] data_out;
 bit wr,rd;        // Read and write control bits
 bit full,empty;

constraint op_crt{ 

op dist {1:/50,0:/50}; // Constraint to randomize 'oper' with 50% probability of 1 and 50% probability of 0
}

constraint dta_ctr{
data_in inside{[30:40]}; //constraint resticting data input btw 30 and 40
}
endclass


