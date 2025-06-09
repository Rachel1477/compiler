# 问题1
正常编译
```
bison -d q1.y
flex q1.l
gcc -o q1_parser q1.tab.c lex.yy.c -lfl

```

# 问题2
```
# 1. Generate C files from the lexer and parser definitions
flex -o lex.yy.c q2.l
bison -d -o q2.tab.c q2.y

# 2. Compile the generated C files into an executable
gcc -o my_checker q2.tab.c lex.yy.c -lfl

# 3. Run the checker
./my_checker
```

使用须知：

在输入待推理的代码之后按ctrl +D开始推理

如：
```
a = 1;
b = a + 2;
if a < b then
  c = 3
else
  c = 4
fi
```
然后ctrl + D

正常会输出  

Parsing completed successfully.
Variables defined at the end: { b a c }
