"hzip.st was completed using pair programing by Andre Yamburg and Dylan Welch "

nl := Character nl.

Character extend [
   isPrint [
      ^ (Character space <= self) & (self <= $~)
   ]
   visible [
      self isPrint ifTrue: [^ '$', self asString]
                   ifFalse: [^ self asInteger printStringRadix: 8]
   ]
]

Object subclass: ZeroArray [
   |theArray|

   ZeroArray class >> new [
      self shouldNotImplement.
   ]

   ZeroArray class >> new: size [
      |result|
      result := super new.
      result init: size.
      ^ result
   ]

   init: size [
      theArray := Array new: size.
   ]

   size [
      ^ theArray size.
   ]

   at: index [
      ^ theArray at: index + 1.
   ]

   at: index put: value [
      ^ theArray at: index + 1 put: value.
   ]

   incr: index [
      (self at: index) isNil
         ifTrue: [ self at: index put: 0].
      self at: index put: (self at: index) + 1.
   ]

   keysAndValuesDo: aBlock [
      (0 to: (self size) - 1) do: [:index |
         aBlock value: index value: (self at: index).
      ]
   ]

]


Object subclass: Leaf [
   |char count isLeaf|
   char [ ^ char ]
   count [ ^ count ]
   isLeaf [ ^ isLeaf ]

   Leaf class >> new [
      self shouldNotImplement
   ]

   Leaf class >> new: aChar count: aCount [
      |result|
      result := super new.
      result setChar: aChar andCount: aCount.
      ^result
   ]

   setChar: aChar andCount: aCount [
      char := aChar.
      count := aCount.
      isLeaf := true.
   ]

   <= other [
      ^ (count < other count)
      | ((count = other count) & (char <= other char))
   ]

   printBase: aStream [
      ^ aStream << self class << '(' << char << ',' << count
   ]

   printOn: aStream [
      (self printBase: aStream) << ')'.
   ]

   inorder: visitor prefix: string [
      visitor value: char value: string.
   ]

   postorder: visitor [
      visitor value: isLeaf value: char.
   ]

   getIsLeaf[
      ^isLeaf.
   ]

   getChar[
      ^char.
   ]

]

Leaf subclass: Tree [
   |left right|

   Tree class >> new: aChar count: aCount [
      self shouldNotImplement
   ]

   Tree class >> new: aChar count: aCount left: aLeft right: aRight [
      |result|
      result := super new: aChar count: aCount.
      result setLeft: aLeft andRight: aRight.
      ^ result
   ]

   setLeft: aLeft andRight: aRight [
      left := aLeft.
      right := aRight.
      isLeaf := false
   ]

   printOn: aStream [
      (self printBase: aStream) << ',' << left << ',' << right << ')'.
   ]

   inorder: visitor prefix: string [
      left inorder: visitor prefix: string, '0'.
      right inorder: visitor prefix: string, '1'.
   ]

   postorder: visitor [
      left postorder: visitor.
      right postorder: visitor.
      visitor value: isLeaf value: char.
   ]

   getRight[
      ^right
   ]

   getLeft[
      ^left
   ]

]

Object subclass: OutBits [
   |bitIndex currentByte myStream|
   OutBits class >> new [
      self shouldNotImplement.
   ]
   OutBits class >> new: fileStream [
      |result|
      result := super new.
      result init: fileStream.
      ^result
   ]
   clearByte [
      bitIndex := 8.
      currentByte := 0.
   ]
   init: fileStream [
      myStream := fileStream.
      self clearByte.
   ]
   flushByte [
      bitIndex = 8 ifFalse: [
         myStream nextPutByte: currentByte.
         self clearByte.
      ]
   ]
   writeBit: bit [
      currentByte := currentByte bitAt: bitIndex put: bit.
      bitIndex := bitIndex - 1.
      bitIndex = 0 ifTrue: [self flushByte].
   ]
]

Object subclass: BitStream [
   |bitIndex byte myStream|
   BitStream class >> new: fileStream [
      |result|
      result := super new.
      result init: fileStream.
      ^result
   ]
   init: fileStream [
      myStream := fileStream.
      bitIndex := 1.
   ]
   nextBit [
      bitIndex = 1 ifTrue: [
         byte := myStream next.
         bitIndex := 9.
      ].
      bitIndex := bitIndex - 1.
      ^byte value bitAt: bitIndex
   ]
   atEnd [
      ^bitIndex = 1 and: [myStream atEnd]
   ]
   currByte [
      ^byte
   ]
]

"*************start of main***********"

args := Smalltalk arguments.
((args at: 1) = '-c') | ((args at: 1) = '-t') ifTrue:[
  [
  Fstream := FileStream open: (args at: 2) mode: FileStream read.
  ] on: SystemExceptions.FileError do: [:signal |
     |errno|
     errno := File errno.
     stdout flush.
     stderr << execname << ': ' << filename << ': '
            << signal messageText << nl.
     stderr flush.
  ].

  FreqArray := ZeroArray new: 257.

  [Fstream atEnd not] whileTrue:[
  |char|
    char := Fstream next.
    FreqArray incr:(char asInteger).
  ].

  FreqArray incr:256.

  Sc := SortedCollection new.

  FreqArray keysAndValuesDo:[:k :v|
     v isNil ifFalse:[
       leaf := Leaf new:(k asCharacter) count: v.
       Sc add: leaf.
     ]
  ].

  [Sc size > 1] whileTrue:[
    |tree left right sum|
    left := Sc removeFirst.
    right := Sc removeFirst.
    sum := left count + right count.
    tree := Tree new: (left char) count: sum left: left right: right.
    Sc add: tree.
  ].

  EncodingArray := ZeroArray new: 257.

  root := Sc removeFirst.

  root inorder:[:char :encoded|
    EncodingArray at:(char asInteger)
      put: encoded.
  ]prefix: ''.

  (args at: 1) = '-t' ifTrue:[
    1 to: 256 do:[:x|
      |v|
      v := FreqArray at: x.
      e := EncodingArray at: x.
      x = 32 
       ifTrue:['x20' display]
       ifFalse:[
        x = 10
         ifTrue:['x0A' display]
         ifFalse:[
          x = 256
           ifTrue:['EOF' display]
           ifFalse:[
             e isNil ifFalse:[x asCharacter display].
                   ].
                 ].
               ].
      v isNil ifFalse:['  ' display. v display. '  ' display].
      e isNil ifFalse:[e displayNl].
    ].
  ].

  (args at: 1) = '-c' ifTrue:[
    metaData := ''.

    root postorder: [:isLeaf :c|
      isLeaf ifFalse:[metaData := metaData, '1'].

      isLeaf ifTrue:[
        (c asInteger) == 256
          ifTrue:[metaData := metaData, '0000000001']
          ifFalse:[
            metaData := metaData, '0'.
            8 to: 1 by:-1 do:[:x|
              |bit|
              bit := ((c asInteger) bitAt: x) asString.
              metaData := metaData, bit.
            ].
            (c asInteger) == 0 ifTrue:[metaData := metaData, '0']
          ]

        ]
    ].
    metaData := metaData, '1'.
    [
    Estream := FileStream open: (args at: 2) mode: FileStream read.
    ] on: SystemExceptions.FileError do: [:signal |
       |errno|
       errno := File errno.
       stdout flush.
       stderr << execname << ': ' << filename << ': '
              << signal messageText << nl.
       stderr flush.
    ].
    writeData := [:outfile|
       |outBytes char encoded|
       outBytes := OutBits new: outfile.
       metaData do: [:bit|
        outBytes writeBit: ((bit asInteger)-48).
       ].

      [Estream atEnd not] whileTrue:[
        char := Estream next.
        encoded := EncodingArray at: (char asInteger).

        encoded do: [:bit|
         outBytes writeBit: ((bit asInteger)-48).
        ].
       ].
       encoded := EncodingArray at: 256.
       encoded do: [:bit|
        outBytes writeBit: ((bit asInteger)-48).
       ].

      outBytes flushByte.
    ].

    (args size) == 3
      ifTrue:[
        [
        Ostream := FileStream open: (args at: 3) mode: FileStream write.
        writeData value: Ostream.
        ] on: SystemExceptions.FileError do: [:signal |
           |errno|
           errno := File errno.
           stdout flush.
           stderr << execname << ': ' << filename << ': '
                  << signal messageText << nl.
           stderr flush.
        ].
      ]
      ifFalse:[writeData value: stdout].
  ].
].

(args at: 1) = '-d' ifTrue:[
  args display
].

(args at: 1) = '-u' ifTrue:[
  |exit out|
  exit := false.
  [
  Estream := FileStream open: (args at: 2) mode: FileStream read.
  ] on: SystemExceptions.FileError do: [:signal |
     |errno|
     errno := File errno.
     stdout flush.
     stderr << execname << ': ' << filename << ': '
            << signal messageText << nl.
     stderr flush.
  ].

  stdinBits := BitStream new: Estream.
  Oc := OrderedCollection new.

  [exit == false] whileTrue:[
    |bit currentByte|
    bit := stdinBits nextBit.
    currentByte := 0.
    bit == 0
      ifTrue:[
        |leaf|
        8 to: 1 by:-1 do:[:x|
          bit := stdinBits nextBit.
          currentByte := currentByte bitAt: x put: bit.
        ].
        currentByte == 0 ifTrue:[
          bit := stdinBits nextBit.
          bit == 1 ifTrue:[currentByte := currentByte + 256].
        ].
        leaf := Leaf new: (currentByte asCharacter) count: 0.
        Oc addFirst: leaf.
      ]
      ifFalse:[
        Oc size == 1
          ifFalse:[
            |tree left right sum|
            right := Oc removeFirst.
            left := Oc removeFirst.
            sum := left count + right count.
            tree :=
            Tree new: (left char) count: sum left: left right: right.
            Oc addFirst: tree.
          ]
          ifTrue:[exit := true].
      ].
  ].
  (args size) == 3
    ifFalse:[out := stdout]
    ifTrue:[
      [
        Ostream := FileStream open: (args at: 3) mode: FileStream write.
        out := Ostream.
      ] on: SystemExceptions.FileError do: [:signal |
         |errno|
         errno := File errno.
         stdout flush.
         stderr << execname << ': ' << filename << ': '
                << signal messageText << nl.
         stderr flush.
      ]
    ].

  exit := false.
  tree := Oc removeLast.
  fulltree := tree.
  tree getIsLeaf ifTrue:[exit := true].
  [exit == true] whileFalse: [
    |bit currentByte|
    bit := stdinBits nextBit.
    bit = 0
      ifTrue:[
        tree := tree getLeft.
        tree getIsLeaf ifTrue:[
          ((tree getChar) asInteger) == 256
            ifTrue:[exit := true]
            ifFalse:[
              out nextPutByte: ((tree getChar) asInteger).
              tree := fulltree.
            ]
        ]
      ]
      ifFalse:[
        tree := tree getRight.
        tree getIsLeaf ifTrue:[
        ((tree getChar) asInteger) == 256
          ifTrue:[exit := true]
          ifFalse:[
            out nextPutByte: ((tree getChar) asInteger).
            tree := fulltree.
          ]
        ]
      ]
  ].
]
