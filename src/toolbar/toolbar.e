OPT MODULE,OSVERSION=40

MODULE 'graphics/gfx','graphics/sprite','exec/memory',
    'intuition/intuition','intuition/screens','utility/tagitem'

-> TODO: Fix AGA and SuperAGA sprite support
CONST BITDEPTH=2
CONST BYTESPERPLANE=2
CONST BYTESPERROW=BYTESPERPLANE*BITDEPTH
CONST NUMCONTROLWORDS=2
CONST MINSPRITE=2
CONST SPRPALETTEMASK=6
CONST NUMPALETTEENTRIES=1 << BITDEPTH
-> TODO: Define as height of drag bar move gadget
CONST MOVEGADHEIGHT=0

#define SPRBUFSIZE(h) (((h)+NUMCONTROLWORDS)*BYTESPERROW)+MOVEGADHEIGHT
#define SPRPALETTEBASE(s) ((s) AND SPRPALETTEMASK)*NUMPALETTEENTRIES

EXPORT OBJECT toolbar PRIVATE
    wndw:PTR TO window
    buf
    scrn:PTR TO screen
    bm:PTR TO bitmap
    spritenum:CHAR
    palettebase:CHAR
ENDOBJECT

-> Constructor for toolbar
-> height must be less than or equal to 512
-> tags is a taglist for AGA capabilities and SuperAGA on Apollo Core
PROC create(x,y,height,tags) OF toolbar
    DEF bufsize:REG,count:REG,spr:PTR TO simplesprite
    -> Allocate memory for bitmap data
    height:=height+MOVEGADHEIGHT
    bufsize:=SPRBUFSIZE(height)
    self.buf:=NewM(bufsize,MEMF_CHIP)
    -> generate bitmap structure from the sprite buffer
    self.bm:=[BYTESPERROW,height,BMF_INTERLEAVED,2,
        self.buf+BYTESPERROW, self.buf+BYTESPERROW+BYTESPERPLANE]:bitmap
    -> allocate sprite 2 or greater
    spr:=[self.buf, height, x, y, -1]:simplesprite
    count:=MINSPRITE-1
    REPEAT
        INC count
        IF count>7 THEN Raise("SPR")
        self.spritenum:=GetSprite(spr, count)
    UNTIL self.spritenum<>-1
    self.palettebase:=SPRPALETTEBASE(self.spritenum)
    -> Build a screen structure using the bitmap
    self.scrn:=OpenScreenTagList(NIL, [
        SA_HEIGHT, height,
        SA_WIDTH, BYTESPERPLANE*8,
        SA_BITMAP, self.bm,
        SA_QUIET, TRUE,
        SA_BEHIND, TRUE,
        SA_DEPTH, BITDEPTH,
        TAG_DONE
    ])
    -> open the actual window
    self.wndw:=OpenWindowTagList(NIL, [
        WA_LEFT, 0,
        WA_TOP, 0+MOVEGADHEIGHT,
        WA_WIDTH, BYTESPERPLANE*8,
        WA_HEIGHT, height,
        WA_SIZEGADGET, FALSE,
        WA_DRAGBAR, FALSE,
        WA_CLOSEGADGET, FALSE,
        WA_CUSTOMSCREEN, TRUE,
        WA_NOCAREREFRESH, TRUE,
        WA_BACKDROP, TRUE,
        WA_BORDERLESS, TRUE,
        TAG_DONE
    ])
ENDPROC

PROC free() OF toolbar
    CloseWindow(self.wndw)
    CloseScreen(self.scrn)
    FreeSprite(self.spritenum)
ENDPROC
