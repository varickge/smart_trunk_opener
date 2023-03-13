classdef DataFormat < uint8
    enumeration

        Auto         (255)
        Disabled     (0)

        U8           (01)
        U16          (02)
        U32          (03)
        U64          (04)
        Signed8      (05)
        Signed16     (06)
        Signed32     (07)
        Signed64     (08)
        Bits         (09)

        Q15          (10)
        Q31          (11)
        Half         (12)
        ComplexQ15   (13)
        ComplexQ31   (14)
        ComplexHalf  (15)

        Packed12     (16)

        Raw10        (43)
        Raw12        (44)
        Raw14        (45)
        Raw16        (02)

    end
end
