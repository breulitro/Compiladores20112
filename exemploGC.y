
%{
  import java.io.*;
  import java.util.ArrayList;
  import java.util.Stack;
%}


%token ID, INT, FLOAT, BOOL, NUM, LIT, VOID, MAIN, READ, WRITE, IF, ELSE
%token WHILE,TRUE, FALSE, IF, ELSE
%token EQ, LEQ, GEQ, NEQ
%token AND, OR
%token FOR, BREAK, CONTINUE, PLUSPLUS, MINUSMINUS

%right '='
%left OR
%left AND
%left  '>' '<' EQ LEQ GEQ NEQ
%left '+' '-'
%left '*' '/' '%'
%left '!'

%type <sval> ID
%type <sval> LIT
%type <sval> NUM
%type <ival> type


%%

prog : { geraInicio(); } dList mainF { geraAreaDados(); geraAreaLiterais(); } ;

mainF : VOID MAIN '(' ')'   { System.out.println("_start:"); }
		'{' lcmd  { geraFinal(); } '}'
		;

dList : decl dList | ;

decl : type ID ';' {  TS_entry nodo = ts.pesquisa($2);
						if (nodo != null)
							yyerror("(sem) variavel >" + $2 + "< jah declarada");
						else ts.insert(new TS_entry($2, $1)); }
	;

type : INT	{ $$ = INT; }
	 | FLOAT  { $$ = FLOAT; }
	 | BOOL   { $$ = BOOL; }
	 ;

lcmd : lcmd cmd
	   |
	   ;
	   
cmd :   '{' lcmd '}'
	| exp ';'
	  | WRITE '(' LIT ')' ';' { strTab.add($3);
								System.out.println("\tMOVL $_str_"+strCount+"Len, %EDX"); 
				System.out.println("\tMOVL $_str_"+strCount+", %ECX"); 
								System.out.println("\tCALL _writeLit"); 
				System.out.println("\tCALL _writeln"); 
								strCount++;
				}
	  
	  | WRITE '(' LIT 
							  { strTab.add($3);
								System.out.println("\tMOVL $_str_"+strCount+"Len, %EDX"); 
				System.out.println("\tMOVL $_str_"+strCount+", %ECX"); 
								System.out.println("\tCALL _writeLit"); 
				strCount++;
				}

					',' exp ')' ';' 
			{ 
			 System.out.println("\tPOPL %EAX"); 
			 System.out.println("\tCALL _write");	
			 System.out.println("\tCALL _writeln"); 
						}
		 
	 | READ '(' ID ')' ';'								
								{
									System.out.println("\tPUSHL $_"+$3);
									System.out.println("\tCALL _read");
									System.out.println("\tPOPL %EDX");
									System.out.println("\tMOVL %EAX, (%EDX)");
									
								}
		 
	| WHILE {
					pRot.push(proxRot);  proxRot += 2;
					System.out.printf("rot_%02d:\n",pRot.peek());
			} '(' exp ')' {
							System.out.println("\tPOPL %EAX");
							System.out.println("\tCMPL $0, %EAX");
							System.out.printf("\tJE rot_%02d\n", (int)pRot.peek()+1);
						} cmd {
							System.out.printf("\tJMP rot_%02d\n", pRot.peek());
							System.out.printf("rot_%02d:\n",(int)pRot.peek()+1);
							pRot.pop();
						}
	| FOR '(' e1 {
				pRot.push(proxRot); proxRot += 4;
				System.out.printf("rot_%02d:\n", pRot.peek() + 2);
			} e2 {
				System.out.println("POPL %EAX");
				System.out.println("CMPL $0, %EAX");
				System.out.printf("JE rot_%02d\n", pRot.peek()+1);
				System.out.printf("JMP rot_%02d\n", pRot.peek()+3);
				System.out.printf("rot_%02d:\n", pRot.peek());
			} e3 ')' {
				System.out.printf("JMP rot_%02d\n", pRot.peek() + 2);
				System.out.printf("rot_%02d:\n", pRot.peek()+3);
			} cmd {
				System.out.printf("JMP rot_%02d\n", pRot.peek());
				System.out.printf("rot_%02d:\n", pRot.peek()+1);
				pRot.pop();
			}
	| IF '(' exp {
				iRot.push(proxRot);  proxRot += 2;
				System.out.println("\tPOPL %EAX");
				System.out.println("\tCMPL $0, %EAX");
				System.out.printf("\tJE rot_%02d\n", iRot.peek());
				}')' cmd restoIf {
							System.out.printf("rot_%02d:\n",iRot.peek()+1);
							iRot.pop();
						}
	| BREAK ';' {
		if (!pRot.empty()) {
			System.out.printf("\tJMP rot_%02d\n", pRot.peek() + 1);
		} else {
			System.out.printf("Nao to num laço!\n");
			System.exit(0);
		}
	}
	| CONTINUE ';' {
		if (!pRot.empty()) {
			System.out.printf("\tJMP rot_%02d\n", pRot.peek());
		} else {
			System.out.printf("Nao to num laço!\n");
			System.exit(0);
		}
	}

	;
e1: exp';'|';';
e2: exp';'|';';
e3: exp|;

restoIf : ELSE  {
				System.out.printf("\tJMP rot_%02d\n", iRot.peek()+1);
				System.out.printf("rot_%02d:\n",iRot.peek());
				} cmd
		| {
			System.out.printf("rot_%02d:\n",iRot.peek()+1);
			System.out.printf("rot_%02d:\n",iRot.peek());
			}
		;

exp :ID '=' exp {
			System.out.println("\tPOPL %EDX");
			System.out.println("\tMOVL %EDX, _"+$1);
			System.out.println("PUSHL _" + $1);
		}
	| NUM  { System.out.println("\tPUSHL $"+$1); }
	| TRUE  { System.out.println("\tPUSHL $1"); }
	| FALSE  { System.out.println("\tPUSHL $0"); }
	| ID   { System.out.println("\tPUSHL _"+$1); }

	| '!' exp	   { gcExpNot(); }
	| exp '+' exp		{ gcExpArit('+'); }
	| exp '-' exp		{ gcExpArit('-'); }
	| exp '*' exp		{ gcExpArit('*'); }
	| exp '/' exp		{ gcExpArit('/'); }
	| exp '%' exp		{ gcExpArit('%'); }
	| exp '>' exp		{ gcExpRel('>'); }
	| exp '<' exp		{ gcExpRel('<'); }
	| exp EQ exp		{ gcExpRel(EQ); }
	| exp LEQ exp		{ gcExpRel(LEQ); }
	| exp GEQ exp		{ gcExpRel(GEQ); }
	| exp NEQ exp		{ gcExpRel(NEQ); }
	| exp OR exp		{ gcExpRel(OR); }
	| exp AND exp		{ gcExpRel(AND); }
	| PLUSPLUS	ID	{
		System.out.println("PUSHL _" + $2);
		System.out.println("PUSHL $1");
		gcExpArit('+');
		System.out.println("POPL %EDX");
		System.out.println("MOVL %EDX, _" + $2);
		System.out.println("PUSHL _" + $2);

	}
	| ID PLUSPLUS {
		System.out.println("PUSHL _" + $1);
		System.out.println("PUSHL $1");
		gcExpArit('+');
		System.out.println("POPL %EDX");
		System.out.println("PUSHL _" + $1);
		System.out.println("MOVL %EDX, _" + $1);

	}
	| MINUSMINUS	ID	{
		System.out.println("PUSHL _" + $2);
		System.out.println("PUSHL $1");
		gcExpArit('-');
		System.out.println("POPL %EDX");
		System.out.println("MOVL %EDX, _" + $2);
		System.out.println("PUSHL _" + $2);

	}
	| ID MINUSMINUS {
		System.out.println("PUSHL _" + $1);
		System.out.println("PUSHL $1");
		gcExpArit('-');
		System.out.println("POPL %EDX");
		System.out.println("PUSHL _" + $1);
		System.out.println("MOVL %EDX, _" + $1);

	}
	;


%%

  private Yylex lexer;

  private TabSimb ts = new TabSimb();

  private int strCount = 0;
  private ArrayList<String> strTab = new ArrayList<String>();

  private Stack<Integer> pRot = new Stack<Integer>();
  private Stack<Integer> iRot = new Stack<Integer>();
  private int proxRot = 1;


  public static int ARRAY = 100;


  private int yylex () {
	int yyl_return = -1;
	try {
	  yylval = new ParserVal(0);
	  yyl_return = lexer.yylex();
	}
	catch (IOException e) {
	  System.err.println("IO error :"+e);
	}
	return yyl_return;
  }


  public void yyerror (String error) {
	System.err.println ("Error: " + error + "  linha: " + lexer.getLine());
  }


  public Parser(Reader r) {
	lexer = new Yylex(r, this);
  }  

  public void setDebug(boolean debug) {
	yydebug = debug;
  }

  public void listarTS() { ts.listar();}

  public static void main(String args[]) throws IOException {

	Parser yyparser;
	if ( args.length > 0 ) {
	  // parse a file
	  yyparser = new Parser(new FileReader(args[0]));
	  yyparser.yyparse();
	  // yyparser.listarTS();

	}
	else {
	  // interactive mode
	  System.out.println("\n\tFormato: java Parser entrada.cmm >entrada.s\n");
	}

  }

							
		void gcExpArit(int oparit) {
 				System.out.println("\tPOPL %EDX");
   			System.out.println("\tPOPL %EAX");

   		switch (oparit) {
	 		case '+' : System.out.println("\tADDL %EDX, %EAX" ); break;
	 		case '-' : System.out.println("\tSUBL %EDX, %EAX" ); break;
	 		case '*' : System.out.println("\tIMULL %EDX, %EAX" ); break;
	 		case '/':  System.out.println("\tMOVL %EAX, %EBX");
					 System.out.println("\tMOVL %EDX, %EAX");
		   			 System.out.println("\tMOVL $0, %EDX");
		   			 System.out.println("\tIDIVL %EBX");
		   			 break;
	 		case '%':  System.out.println("\tMOVL %EAX, %EBX");
					 System.out.println("\tMOVL %EDX, %EAX");
		   			 System.out.println("\tMOVL $0, %EDX");
		   			 System.out.println("\tIDIVL %EBX");
		   			 System.out.println("\tMOVL %EDX, %EAX");
		   			 break;
			}
   		System.out.println("\tPUSHL %EAX");
		}

	public void gcExpRel(int oprel) {

	System.out.println("\tPOPL %EAX");
	System.out.println("\tPOPL %EDX");
	System.out.println("\tCMPL %EAX, %EDX");
	System.out.println("\tMOVL $0, %EAX");
	
	switch (oprel) {
	   case '<':  			System.out.println("\tSETL  %AL"); break;
	   case '>':  			System.out.println("\tSETG  %AL"); break;
	   case Parser.EQ:  System.out.println("\tSETE  %AL"); break;
	   case Parser.GEQ: System.out.println("\tSETGE %AL"); break;
	   case Parser.LEQ: System.out.println("\tSETLE %AL"); break;
	   case Parser.NEQ: System.out.println("\tSETNE %AL"); break;
	   }
	
	System.out.println("\tPUSHL %EAX");

	}


	public void gcExpLog(int oplog) {

	   	System.out.println("\tPOPL %EDX");
 		 	System.out.println("\tPOPL %EAX");

  	 	System.out.println("\tCMPL $0, %EAX");
 		  System.out.println("\tMOVL $0, %EAX");
   		System.out.println("\tSETNE %AL");
   		System.out.println("\tCMPL $0, %EDX");
   		System.out.println("\tMOVL $0, %EDX");
   		System.out.println("\tSETNE %DL");

   		switch (oplog) {
				case Parser.OR:  System.out.println("\tORL  %EDX, %EAX");  break;
				case Parser.AND: System.out.println("\tANDL  %EDX, %EAX"); break;
	   }

		System.out.println("\tPUSHL %EAX");
	}

	public void gcExpNot(){

  	 System.out.println("\tPOPL %EAX" );
 	   System.out.println("	\tNEGL %EAX" );
  	 System.out.println("	\tPUSHL %EAX");
	}

   private void geraInicio() {
			System.out.println(".text\n\n#\t nome COMPLETO e matricula dos componentes do grupo...\n#\n"); 
			System.out.println(".GLOBL _start\n\n");  
   }

   private void geraFinal(){
	
			System.out.println("\n\n");
			System.out.println("#");
			System.out.println("# devolve o controle para o SO (final da main)");
			System.out.println("#");
			System.out.println("\tmov $0, %ebx");
			System.out.println("\tmov $1, %eax");
			System.out.println("\tint $0x80");
	
			System.out.println("\n");
			System.out.println("#");
			System.out.println("# Funcoes da biblioteca (IO)");
			System.out.println("#");
			System.out.println("\n");
			System.out.println("_writeln:");
			System.out.println("\tMOVL $__fim_msg, %ECX");
			System.out.println("\tDECL %ECX");
			System.out.println("\tMOVB $10, (%ECX)");
			System.out.println("\tMOVL $1, %EDX");
			System.out.println("\tJMP _writeLit");
			System.out.println("_write:");
			System.out.println("\tMOVL $__fim_msg, %ECX");
			System.out.println("\tMOVL $0, %EBX");
			System.out.println("\tCMPL $0, %EAX");
			System.out.println("\tJGE _write3");
			System.out.println("\tNEGL %EAX");
			System.out.println("\tMOVL $1, %EBX");
			System.out.println("_write3:");
			System.out.println("\tPUSHL %EBX");
			System.out.println("\tMOVL $10, %EBX");
			System.out.println("_divide:");
			System.out.println("\tMOVL $0, %EDX");
			System.out.println("\tIDIVL %EBX");
			System.out.println("\tDECL %ECX");
			System.out.println("\tADD $48, %DL");
			System.out.println("\tMOVB %DL, (%ECX)");
			System.out.println("\tCMPL $0, %EAX");
			System.out.println("\tJNE _divide");
			System.out.println("\tPOPL %EBX");
			System.out.println("\tCMPL $0, %EBX");
			System.out.println("\tJE _print");
			System.out.println("\tDECL %ECX");
			System.out.println("\tMOVB $'-', (%ECX)");
			System.out.println("_print:");
			System.out.println("\tMOVL $__fim_msg, %EDX");
			System.out.println("\tSUBL %ECX, %EDX");
			System.out.println("_writeLit:");
			System.out.println("\tMOVL $1, %EBX");
			System.out.println("\tMOVL $4, %EAX");
			System.out.println("\tint $0x80");
			System.out.println("\tRET");
			System.out.println("_read:");
			System.out.println("\tMOVL $15, %EDX");
			System.out.println("\tMOVL $__msg, %ECX");
			System.out.println("\tMOVL $0, %EBX");
			System.out.println("\tMOVL $3, %EAX");
			System.out.println("\tint $0x80");
			System.out.println("\tMOVL $0, %EAX");
			System.out.println("\tMOVL $0, %EBX");
			System.out.println("\tMOVL $0, %EDX");
			System.out.println("\tMOVL $__msg, %ECX");
			System.out.println("\tCMPB $'-', (%ECX)");
			System.out.println("\tJNE _reading");
			System.out.println("\tINCL %ECX");
			System.out.println("\tINC %BL");
			System.out.println("_reading:");
			System.out.println("\tMOVB (%ECX), %DL");
			System.out.println("\tCMP $10, %DL");
			System.out.println("\tJE _fimread");
			System.out.println("\tSUB $48, %DL");
			System.out.println("\tIMULL $10, %EAX");
			System.out.println("\tADDL %EDX, %EAX");
			System.out.println("\tINCL %ECX");
			System.out.println("\tJMP _reading");
			System.out.println("_fimread:");
			System.out.println("\tCMPB $1, %BL");
			System.out.println("\tJNE _fimread2");
			System.out.println("\tNEGL %EAX");
			System.out.println("_fimread2:");
			System.out.println("\tRET");
			System.out.println("\n");
	 }

	 private void geraAreaDados(){
			System.out.println("");		
			System.out.println("#");
			System.out.println("# area de dados");
			System.out.println("#");
			System.out.println(".data");
			System.out.println("#");
			System.out.println("# variaveis globais");
			System.out.println("#");
			ts.geraGlobais();	
			System.out.println("");
	
	}

	 private void geraAreaLiterais() { 

		 System.out.println("#\n# area de literais\n#");
		 System.out.println("__msg:");
		   System.out.println("\t.zero 30");
		   System.out.println("__fim_msg:");
		   System.out.println("\t.byte 0");
		   System.out.println("\n");

		 for (int i = 0; i<strTab.size(); i++ ) {
			 System.out.println("_str_"+i+":");
			 System.out.println("\t .ascii \""+strTab.get(i)+"\""); 
			   System.out.println("_str_"+i+"Len = . - _str_"+i);  
		  }		
   }
   
