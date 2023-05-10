OPT OSVERSION=40,PREPROCESS

#ifndef EVO_3_6_0
    FATAL('Requires E-VO compiler version 3.6.0 or newer')
#endif

#ifdef DEBUG
    #define TRACE WriteF
#else
    #define TRACE ->
#endif

MODULE 'intuition/intuition','dos/dos'

ENUM ERR_OK

PROC openFile(file)
    DEF buf[144]:STRING
    RightStr(buf,file,4)
    UpperStr(buf)
    IF StrCmp(buf,'.GUI')
        RETURN
    ENDIF
    TRACE('Skipping illegal filename "\s"\n',file)
ENDPROC

PROC processArgs()
    DEF rdargs:PTR TO RdArgs,
        wb:PTR TO wbstartup,
        wbArguments:PTR TO wbarg,
        files:PTR TO LONG,
        files2,
        x
    IF wbmessage -> launched from Workbench
        wb:=wbmessage
        wbArguments:=wb.arglist
        files:=List(wb.numargs)
        CopyMem({wbArguments},{files2},wb.numargs)
    ELSE -> launched from command line
        IF (rdargs:=ReadArgs('FILE/M',files,NIL))=NIL THEN Raise('ARGS')
        files2:=List(ListMax(files))
        ListCopy(files,files2)
        FreeArgs(rdargs)
    ENDIF
    ForAll({x},files2,`openFile(x))
ENDPROC

PROC main() HANDLE
    processArgs()
EXCEPT
    SELECT exception
        CASE ERR_OK
            -> No errors so do nothing
        CASE 'ARGS'
            WriteF('Arguments couldn\'t be read.\n')
        CASE 'MEM'
            WriteF('Out of RAM.\n')
        DEFAULT
            WriteF('An unhandled exception occurred numbered \d.\n', exception)
    ENDSELECT
ENDPROC
