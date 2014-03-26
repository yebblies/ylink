
import std.stdio;
import std.string;
import std.conv;

immutable regname = ["AX", "CX", "DX", "BX", "SP", "BP", "SI", "DI"];
immutable regname32 = ["EAX", "ECX", "EDX", "EBX", "ESP", "EBP", "ESI", "EDI"];

string X86Disassemble(ubyte *ptr)
{
    ubyte op;
    ubyte regrm;
    string name;
    string ovr;

    switch(op = *ptr)
    {
    case 0x00: return "ADD r/m8 r8";
    case 0x01: return "ADD r/m16/32 r16/32";
    case 0x02: return "ADD r8 r/m8";
    case 0x03: return "ADD r16/32 r/m16/32";
    case 0x04: return "ADD AL, " ~ readoff!byte(ptr+1);
    case 0x05: return "ADD eAX imm16/32";
    case 0x06: return "PUSH ES";
    case 0x07: return "POP ES";
    case 0x08: return "OR r/m8 r8";
    case 0x09: return "OR r/m16/32 r16/32";
    case 0x0A: return "OR r8 r/m8";
    case 0x0B: return "OR r16/32 r/m16/32";
    case 0x0C: return "OR AL, " ~ readoff!byte(ptr+1);
    case 0x0D: return "OR eAX imm16/32";
    case 0x0E: return "PUSH CS";
    case 0x0F: return prefix(op, ptr+1);
    case 0x10: return "ADC r/m8 r8";
    case 0x11: return "ADC r/m16/32 r16/32";
    case 0x12: return "ADC r8 r/m8";
    case 0x13: return "ADC r16/32 r/m16/32";
    case 0x14: return "ADC AL, " ~ readoff!byte(ptr+1);
    case 0x15: return "ADC eAX imm16/32";
    case 0x16: return "PUSH SS";
    case 0x17: return "POP SS";
    case 0x18: return "SBB r/m8 r8";
    case 0x19: return "SBB r/m16/32 r16/32";
    case 0x1A: return "SBB r8 r/m8";
    case 0x1B: return "SBB r16/32 r/m16/32";
    case 0x1C: return "SBB AL, " ~ readoff!byte(ptr+1);
    case 0x1D: return "SBB eAX imm16/32";
    case 0x1E: return "PUSH DS";
    case 0x1F: return "POP DS";
    case 0x20: return "AND r/m8 r8";
    case 0x21: return "AND r/m16/32 r16/32";
    case 0x22: return "AND r8 r/m8";
    case 0x23: return "AND r16/32 r/m16/32";
    case 0x24: return "AND AL, " ~ readoff!byte(ptr+1);
    case 0x25: return "AND eAX imm16/32";
    case 0x26: return "override ES";
    case 0x27: return "DAA AL";
    case 0x28: return "SUB r/m8 r8";
    case 0x29: return "SUB r/m16/32 r16/32";
    case 0x2A: return "SUB r8 r/m8";
    case 0x2B: return "SUB r16/32 r/m16/32";
    case 0x2C: return "SUB AL, " ~ readoff!byte(ptr+1);
    case 0x2D: return "SUB eAX imm16/32";
    case 0x2E: return "override CS";
    case 0x2F: return "DAS AL";
    case 0x30: return "XOR r/m8 r8";
    case 0x31: return "XOR r/m16/32 r16/32";
    case 0x32: return "XOR r8 r/m8";
    case 0x33: return "XOR r16/32 r/m16/32";
    case 0x34: return "XOR AL, " ~ readoff!byte(ptr+1);
    case 0x35: return "XOR eAX imm16/32";
    case 0x36: return "override SS";
    case 0x37: return "AAA AL AH";
    case 0x38: return "CMP r/m8 r8";
    case 0x39: return "CMP r/m16/32 r16/32";
    case 0x3A: return "CMP r8 r/m8";
    case 0x3B: return "CMP r16/32 r/m16/32";
    case 0x3C: return "CMP AL, " ~ readoff!byte(ptr+1);
    case 0x3D: return "CMP eAX imm16/32";
    case 0x3E: return "override DS";
    case 0x3F: return "AAS AL AH";
    case 0x40: .. case 0x47:
        return "INC " ~ regname32[op - 0x40];
    case 0x48: .. case 0x4F:
        return "DEC " ~ regname32[op - 0x48];
    case 0x50: .. case 0x57:
        return "PUSH " ~ regname32[op - 0x50];
    case 0x58: .. case 0x5F:
        return "POP " ~ regname32[op - 0x58];
    case 0x60: return "PUSHAD";
    case 0x61: return "POPAD";
    case 0x62: return "BOUND r16/32 m16/32&16/32";
    case 0x63: return "ARPL r/m16 r16";
    case 0x64: return "override FS " ~ X86Disassemble(ptr+1);
    case 0x65: return "override GS";
    case 0x66: return "override 66 " ~ X86Disassemble(ptr+1);
    case 0x67: return "override 67";
    case 0x68: return "PUSH imm16/32";
    case 0x69: return "IMUL r16/32 r/m16/32 imm16/32";
    case 0x6A: return "PUSH " ~ readoff!byte(ptr+1);
    case 0x6B: return "IMUL r16/32 r/m16/32 imm8";
    case 0x6C: return "INS m8 DX";
    case 0x6D: return "INS m16 DX";
    case 0x6E: return "OUTS m8 DX";
    case 0x6F: return "OUTS m16 DX";
    case 0x70: return "JO";
    case 0x71: return "JNO";
    case 0x72: return "JB";
    case 0x73: return "JNB";
    case 0x74: return "JZ";
    case 0x75: return "JNZ";
    case 0x76: return "JBE";
    case 0x77: return "JNBE";
    case 0x78: return "JS";
    case 0x79: return "JNS";
    case 0x7A: return "JP";
    case 0x7B: return "JNP";
    case 0x7C: return "JL";
    case 0x7D: return "JNL";
    case 0x7E: return "JLE";
    case 0x7F: return "JNLE";
    case 0x80: return extend8X(ptr);
    case 0x81: return extend8X(ptr);
    case 0x82: return extend8X(ptr);
    case 0x83: return extend8X(ptr);
    case 0x84: return "TEST r/m8 r8";
    case 0x85: return "TEST r/m16/32 r16/32";
    case 0x86: return "XCHG r8 r/m8";
    case 0x87: return "XCHG r16/32 r/m16/32";
    case 0x88: return "MOV r/m8 r8";
    case 0x89: return "MOV r/m16/32/ r16/32";
    case 0x8A: return "MOV r8 r/m8";
    case 0x8B: return "MOV " ~ modrm32(ptr+1); //16/32 r/m16/32
    case 0x8C: return "MOV r/m16 Sreg";
    case 0x8D: return "LEA r16/32";
    case 0x8E: return "MOV Sreg r/m16";
    case 0x8F: return "POP r/m16/32";
    case 0x90: .. case 0x97:
        return "XCHG eAX " ~ regname32[op - 0x90];
    case 0x99: return "CWD EDX EAX";
    case 0x9B: return "FWAIT";
    case 0x9C: return "PUSHFD";
    case 0x9D: return "POPF";
    case 0x9E: return "SAHF AH";
    case 0xA0: return "MOV AL, [" ~ readabs!ubyte(ptr+1) ~ "]";
    case 0xA1: return "MOV EAX, [" ~ readabs!uint(ptr+1) ~ "]";
    case 0xA2: return "MOV [" ~ readabs!ubyte(ptr+1) ~ "], AL";
    case 0xA3: return "MOV [" ~ readabs!uint(ptr+1) ~ "], EAX";
    case 0xA5: return "MOVS m16/32 m16/32";
    case 0xA8:
    case 0xA9: return "TEST";
    case 0xAB: return "STOS";
    case 0xB0: .. case 0xB7:
        return "MOV " ~ regname32[op - 0xB0] ~ ", " ~ readoff!byte(ptr+1);
    case 0xB8: .. case 0xBF:
        return "MOV " ~ regname32[op - 0xB8] ~ " imm16/32";
    case 0xC0: return "group C0";
    case 0xC1: return "group C1";
    case 0xC2: return "RETN imm16";
    case 0xC3: return "RETN";
    case 0xC6: return "group C6";
    case 0xC7: return "group C7";
    case 0xC8: return "ENTER";
    case 0xC9: return "LEAVE";
    case 0xCC: return "INT 3";
    case 0xD0: return "group D0";
    case 0xD1: return "group D1";
    case 0xD2: return "group D2";
    case 0xD3: return "group D3";
    case 0xD8: return "group D8";
    case 0xD9: return "group D9";
    case 0xDA: return "group DA";
    case 0xDB: return "group DB";
    case 0xDC: return "group DC";
    case 0xDD: return "group DD";
    case 0xDE: return "group DE";
    case 0xDF: return "group DF";
    case 0xE3: return "JCXZ";
    case 0xE2: return "LOOP ECX, EIP" ~ readoff!byte(ptr+1);
    case 0xE8: return "CALL EIP" ~ readoff!int(ptr+1);
    case 0xE9: return "JMP EIP" ~ readoff!int(ptr+1);
    case 0xEB: return "JMP EIP" ~ readoff!byte(ptr+1);
    case 0xEC: return "IN AL, DX";
    case 0xF0: return prefix(op, ptr+1);
    case 0xF2: return prefix(op, ptr+1);
    case 0xF3: return prefix(op, ptr+1);
    case 0xF6: return "group F6";
    case 0xF7: return "group F7";
    case 0xFC: return "CLD";
    case 0xFE: return "group FE";
    case 0xFF: return groupFF(ptr);
    default:
        writefln("Unknown opcode: %.2X", op);
        assert(0);
    }
}

string prefix(ubyte pre, ubyte *ptr)
{
    ubyte op;
    switch(pre)
    {
    case 0x0F:
        switch(op = *ptr)
        {
        case 0x34: return "SYSENTER";
        case 0x80: return "JO imm16/32";
        case 0x81: return "JNO imm16/32";
        case 0x82: return "JB imm16/32";
        case 0x83: return "JNB imm16/32";
        case 0x84: return "JZ imm16/32";
        case 0x85: return "JNZ imm16/32";
        case 0x86: return "JBE imm16/32";
        case 0x87: return "JNBE imm16/32";
        case 0x88: return "JS imm16/32";
        case 0x89: return "JNS imm16/32";
        case 0x8A: return "JP imm16/32";
        case 0x8B: return "JNP imm16/32";
        case 0x8C: return "JL imm16/32";
        case 0x8D: return "JNL imm16/32";
        case 0x8E: return "JLE imm16/32";
        case 0x8F: return "JNLE imm16/32";
        case 0x90: return "SETO imm16/32";
        case 0x91: return "SETNO imm16/32";
        case 0x92: return "SETB imm16/32";
        case 0x93: return "SETNB imm16/32";
        case 0x94: return "SETZ imm16/32";
        case 0x95: return "SETNZ imm16/32";
        case 0x96: return "SETBE imm16/32";
        case 0x97: return "SETNBE imm16/32";
        case 0x98: return "SETS imm16/32";
        case 0x99: return "SETNS imm16/32";
        case 0x9A: return "SETP imm16/32";
        case 0x9B: return "SETNP imm16/32";
        case 0x9C: return "SETL imm16/32";
        case 0x9D: return "SETNL imm16/32";
        case 0x9E: return "SETLE imm16/32";
        case 0x9F: return "SETNLE imm16/32";
        case 0xA2: return "CPUID";
        case 0xA3: return "BT r/m16/32 r16/32";
        case 0xAB: return "BTS " ~ modrm32(ptr+1);
        case 0xAC: return "SHRD r/m16/32 r16/32 imm8";
        case 0xAD: return "SHRD r/m16/32 r16/32 CL";
        case 0xAF: return "IMUL r16/32 r/m16/32";
        case 0xB0: return "CMPXCHG r/m8 AL";
        case 0xB1: return "CMPXCHG r/m16/32 eAX";
        case 0xB6: return "MOVZX r16/32 r/m8";
        case 0xB7: return "MOVZX r16/32 r/m16/32";
        case 0xBE: return "MOVSX r16/32 r/m8";
        case 0xBF: return "MOVSX r16/32 r/m16";
        case 0xC0: return "XADD r/m8 r8";
        case 0xC1: return "XADD r/m16/32 r16/32";
        case 0xC8: .. case 0xCF:
            return "BSWAP " ~ regname32[op - 0xC8];
        default:
            writefln("Unknown opcode: %.2X %.2X", pre, op);
            assert(0);
        }
    case 0xF0:
        return "LOCK " ~ X86Disassemble(ptr);
    case 0xF2:
    case 0xF3:
        auto repstr = (pre == 0xF2) ? "REPNZ" : "REPZ";
        switch(op = *ptr)
        {
        case 0xA4: return repstr ~ " MOVS m8 m8";
        case 0xA5: return repstr ~ " MOVS m16/32 m16/32";
        case 0xA6: return repstr ~ " CMPS m8 m8";
        case 0xA7: return repstr ~ " CMPS m16 m16";
        case 0xAA: return repstr ~ " STOS m8 AL";
        case 0xAB: return repstr ~ " STOS m16/32 eAX";
        case 0xAE: return repstr ~ " SCAS m8 AL";
        case 0xAF: return repstr ~ " SCAS m16/32 eAX";
        default:
            writefln("Unknown opcode: %.2X %.2X", pre, op);
            assert(0);
        }
    default:
        assert(0, "Unknown prefix " ~ to!string(pre));
    }
}

string modrm32(ubyte* ptr)
{
    auto d = *ptr;
    auto mod = d >> 6;
    auto reg2 = (d >> 3) & 0x7;
    auto reg1 = d & 0x7;
    auto haveSIB = false;
    switch(mod)
    {
    case 0:
        if (reg1 == 5) // [32]
        {
            return regname32[reg2] ~ ", [" ~ readoff!uint(ptr+1) ~ "]";
        }
        else if (reg1 == 4)
        {
            haveSIB = true;
            return "SIB";
        }
        else // [reg]
        {
            return regname32[reg2] ~ ", [" ~ regname32[reg1] ~ "]";
        }
    case 1: // [reg+8]
        return regname32[reg2] ~ ", [" ~ regname32[reg1] ~ readoff!byte(ptr+1) ~ "]";
    case 2: // [reg+16]
        return regname32[reg2] ~ ", [" ~ regname32[reg1] ~ "+imm16]";
    case 3: // reg
        return regname32[reg2] ~ ", " ~ regname32[reg1];
    default:
        assert(0);
    }
}

string readoff(T : byte)(ubyte* ptr)
{
    T v = *cast(T*)ptr;
    if (v > 0)
        return format("+%.2X", v);
    else
        return format("-%.2X", -v);
}

string readoff(T : short)(ubyte* ptr)
{
    T v = *cast(T*)ptr;
    if (v > 0)
        return format("+%.4X", v);
    else
        return format("-%.4X", -v);
}

string readoff(T : int)(ubyte* ptr)
{
    T v = *cast(T*)ptr;
    if (v > 0)
        return format("+%.8X", v);
    else
        return format("-%.8X", -v);
}

string readoff(T : uint)(ubyte* ptr)
{
    T v = *cast(T*)ptr;
    return format("+%.8X", v);
}

string readabs(T : ubyte)(ubyte* ptr)
{
    T v = *cast(T*)ptr;
    return format("%.2X", v);
}

string readabs(T : uint)(ubyte* ptr)
{
    T v = *cast(T*)ptr;
    return format("%.8X", v);
}

string extend8X(ubyte* ptr)
{
    auto op = *ptr++;
    auto d = *ptr;
    auto mod = d >> 6;
    auto op2 = (d >> 3) & 0x7;
    auto reg1 = d & 0x7;
    string name = ["ADD", "OR", "ADC", "SBB", "AND", "SUB", "XOR", "CMP"][op2];
    return name ~ " ???";
}

string groupFF(ubyte* ptr)
{
    auto op = *ptr++;
    auto d = *ptr;
    auto mod = d >> 6;
    auto op2 = (d >> 3) & 0x7;
    auto reg1 = d & 0x7;
    assert(op2 != 7);
    string name = ["INC", "DEC", "CALL", "CALLF", "JMP", "JMPF", "PUSH"][op2];
    switch (mod)
    {
    case 0:
        return name ~ " [" ~ readabs!uint(ptr+1) ~ "]";
    default:
        return name ~ " ???";
    }
}
