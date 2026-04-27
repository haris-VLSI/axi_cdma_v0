//list of parameters and Typedefs here--
// signal data type typedefs  -- [ _t is suffix for all typedefs]
typedef logic [6:0]       id_t;
typedef logic [63:0]      address_t;
typedef logic [0:0]       valid_t;
typedef logic [0:0]       ready_t;
typedef logic [7:0]       burst_len_t;
typedef logic [2:0]       burst_size_t;
typedef logic [127:0]     data_t;
typedef logic [15:0]      strobe_t;
typedef logic [0:0]       last_t;
typedef logic [3:0]       region_t;
typedef logic [3:0]       cache_t;
typedef logic [2:0]       prot_t;
typedef logic [3:0]       qos_t;
typedef logic [0:0]       lock_t;
typedef enum {FIXED,INCR,WRAP}              burst_type_t;
typedef enum {OKAY,EXOKAY,SLVERR,DECERR}    response_t;
typedef enum {WRITE,READ}                   command_t;
typedef int  delay_t;
typedef enum {NO_RESET,RESET_ASSERTED,RESET_DEASSERTED}    reset_info_t;
typedef enum {s0,s1,s2,s3}    slave_type;
typedef enum {m0,m1,m2,m3}    master_type;

typedef enum {ONE,MB,SML,MIN,MED,MAX,MAXP}    btt_type_t;
