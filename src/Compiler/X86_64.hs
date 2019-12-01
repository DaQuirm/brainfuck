module Compiler.X86_64 (compile) where

import           Text.Printf (printf)

import           Brainfuck   (AddProd (AddProd), Brainfuck, Operation (ForLoop, IncrementPointer, IncrementValue, Loop, OutputValue, ReadValue, SetValue))

compile :: Brainfuck -> String
compile bf =
    let
        asm = unlines $ map encodeOperation bf
    in
        header ++ asm ++ footer

encodeOperation :: Operation -> String
encodeOperation (IncrementPointer n)    = printf "addq $%d, %%r14" n
encodeOperation (IncrementValue n)      = printf "addb $%d, (%%r15, %%r14, 1)" n
encodeOperation OutputValue             = "call _printChar"
encodeOperation ReadValue               = "call _readChar"
encodeOperation (SetValue x)            = printf "movb $%d, (%%r15, %%r14, 1)" x
encodeOperation (ForLoop lId addProds)  =
  let
    loopStart = printf "\
      \fl%d_start:\n\
      \cmpb $0, (%%r15, %%r14, 1)\n\
      \je fl%d_end\n\n" lId lId

    loopBody  = unlines (map encodeAddProd addProds)

    loopEnd   = printf "fl%d_end:\n" lId
  in
    loopStart ++ loopBody ++ loopEnd

encodeOperation (Loop lId bf)            =
  let
    loopStart = printf "l%d_start:\ncmpb $0, (%%r15, %%r14, 1)\nje l%d_end\n\n" lId lId
    loopEnd   = printf "jmp l%d_start\nl%d_end:\n" lId lId
    loopBody  = unlines $ map encodeOperation bf
  in
    loopStart ++ loopBody ++ loopEnd

encodeAddProd :: AddProd -> String
encodeAddProd (AddProd addr fctr) =
  printf "\
   \movb $%d, %%al\n\
   \mulb (%%r15, %%r14, 1)\n\
   \addb %%al, %d(%%r15, %%r14, 1)\n" fctr addr

header :: String
header = "\n\
  \.section .bss\n\
  \    .lcomm memory, 30000\n\
  \\n\
  \.section .text\n\
  \    .global _start\n\
  \\n\
  \_printChar:\n\
  \movq $1, %rdi       # stdout file descriptor\n\
  \movq $memory, %rsi  # message to print\n\
  \addq %r14, %rsi     # TODO can this be done in one step?\n\
  \movq $1, %rdx       # message length\n\
  \movq $1, %rax       # sys_write\n\
  \syscall\n\
  \ret\n\
  \\n\
  \_readChar:\n\
  \movq $0, %rdi       # stdin file descriptor\n\
  \movq $memory, %rsi  # message to print\n\
  \addq %r14, %rsi     # TODO can this be done in one step?\n\
  \movq $1, %rdx       # message length\n\
  \movq $0, %rax       # sys_read\n\
  \syscall\n\
  \ret\n\
  \\n\
  \_start:\n\
  \movq $memory, %r15\n\
  \movq $0, %r14       # index\n\n"

footer :: String
footer = "\n\
  \movq $0, %rdi       # exit code = 0\n\
  \movq $60, %rax      # sys_exit\n\
  \syscall\n"

