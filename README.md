# nasm-base64
Linux x64 NASM Base64Encoder

## Build instructions:

nasm -f elf64 base64encode.asm

ld base64encode.o -o base64encode

## The encoder reads the data from standard input stream. For example:

echo 'Hello World!' | ./base64encode

## or one can base encode the whole files using pipe:

cat some.file | ./base64encode
