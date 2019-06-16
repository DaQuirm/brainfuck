
module Compiler.X86_64 (compile) where

import System.Process   (callCommand)
import Text.Printf      (printf)

import Brainfuck        (Operation(..), Brainfuck)

compile :: String -> Brainfuck -> IO ()
compile name bf = do
    let assembly = encode bf
    assemble name assembly

encode :: Brainfuck -> String
encode bf =
    let
        asm = unlines $ map encodeOperation bf
    in
        header ++ asm ++ footer

encodeOperation :: Operation -> String
encodeOperation (IncrementPointer n)    = printf "addq $%d, %%r14" n
encodeOperation (IncrementValue n)      = printf "addb $%d, (%%r15, %%r14, 1)" n
encodeOperation OutputValue             = "call _printChar"
encodeOperation ReadValue               = "call _readChar"
encodeOperation (Loop id bf)            =
    let
        loopStart       = printf "l%d_start:\ncmpb $0, (%%r15, %%r14, 1)\nje l%d_end\n\n" id id
        loopEnd         = printf "jmp l%d_start\nl%d_end:\n" id id
        loopBody        = unlines $ map encodeOperation bf
    in
        loopStart ++ loopBody ++ loopEnd

assemble :: String -> String -> IO ()
assemble programName assemblyCode = do
    callCommand $ printf "echo '%s' > '%s'.s" assemblyCode programName
    callCommand $ printf "echo '%s' | as -o %s.o" assemblyCode programName
    callCommand $ printf "ld %s.o -o %s" programName programName

header = "\n\
    \.section .bss\n\
    \    .lcomm memory, 30000\n\
    \\\n\
    \.section .text\n\
    \    .global _start\n\
    \\\n\
    \_printChar:\n\
    \movq $1, %rdi       # stdout file descriptor\n\
    \movq $memory, %rsi  # message to print\n\
    \addq %r14, %rsi     # TODO can this be done in one step?\n\
    \movq $1, %rdx       # message length\n\
    \movq $1, %rax       # sys_write\n\
    \syscall\n\
    \ret\n\
    \\\n\
    \_readChar:\n\
    \movq $0, %rdi       # stdin file descriptor\n\
    \movq $memory, %rsi  # message to print\n\
    \addq %r14, %rsi     # TODO can this be done in one step?\n\
    \movq $1, %rdx       # message length\n\
    \movq $0, %rax       # sys_read\n\
    \syscall\n\
    \ret\n\
    \\\n\
    \_start:\n\
    \movq $memory, %r15\n\
    \movq $0, %r14       # index\n\n"

footer = "\n\
    \movq $0, %rdi       # exit code = 0\n\
    \movq $60, %rax      # sys_exit\n\
    \syscall\n"

