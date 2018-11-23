#include <stdarg.h>
#include <stdint.h>


void _putchar(char n)
{
    volatile unsigned int *p = (unsigned int*)0x80001000;
    
    while ((*p) & 0x80000000);
    *p = n;
    while ((*p) & 0x80000000);
    
}

void _puts (unsigned char* p)
{
    while (*p) {
        _putchar (*p);
        ++p;
    }
}


char *convert(unsigned long long num, unsigned int base) 
{ 
    static char Representation[]= "0123456789ABCDEF";
    static char buffer[200]; 
    char *ptr; 
    
    ptr = &buffer[199]; 
    *ptr = '\0'; 
    
    do 
    { 
        *--ptr = Representation[num%base]; 
        num /= base; 
    }while(num != 0); 
    
    return(ptr); 
}

/*
void debug_printf(const char* str, ...)
{

    char *traverse; 
    unsigned int i; 
    char *s; 
    
    //Module 1: Initializing Myprintf's arguments 
    va_list arg; 
    va_start(arg, str); 
    
    traverse = str;
    while (*traverse) {
        if ((*traverse) != '%') {
            _putchar (*traverse);
            ++traverse;   
        } else {
            ++traverse;
            
            switch(*traverse++) { 
                case 'c' : i = va_arg(arg,int);     //Fetch char argument
                            _putchar(i);
                            break; 
                            
                case 'd' : i = va_arg(arg,int);         //Fetch Decimal/Integer argument
                            if(i<0) 
                            { 
                                i = -i;
                                _putchar('-'); 
                            } 
                            _puts(convert(i,10));
                            break; 
                            
                case 'o': i = va_arg(arg,unsigned int); //Fetch Octal representation
                            _puts(convert(i,8));
                            break; 
                            
                case 's': s = va_arg(arg,char *);       //Fetch string
                            _puts(s); 
                            break; 
                            
                case 'x': i = va_arg(arg,unsigned int); //Fetch Hexadecimal representation
                            _puts(convert(i,16));
                            break; 
            }
            
        }
        
        
    }
    //Module 3: Closing argument list to necessary clean-up
    va_end(arg); 

}
*/
int main (int argc, char** argv)
{
    int i;
    
    /*long long x = 971528;
    long long y = 500;
    long a = 1000000;
    long b = 96000000;
    
    long long z;
    int i;
    for (i = 0; i < 100; ++i) {
        debug_printf ("sdfffffffffff\n");
    }
    if (argc > 10) {
        x = 971528;
        y = 500;
        a = 1000000;
        b = 96000000;
    }
    
    z = x % y;
    */
    _puts("AAA\n");
    
    _puts(convert (28, 10));
    _puts("BBB\n");
    
    
 
 //   debug_printf ("zzz = %d", 28);
}