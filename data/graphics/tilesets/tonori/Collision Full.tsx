<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.0" name="Collision Full" tilewidth="32" tileheight="32" tilecount="20" columns="4">
 <image source="../generic/collision-full.png" width="128" height="160"/>
 <tile id="0">
  <objectgroup draworder="index" id="2">
   <object id="2" x="0" y="32">
    <polygon points="0,0 0,-32 32,-32 32,-16 16,0"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="1">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="0">
    <polygon points="0,0 -32,0 -32,16 0,16"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="2">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="32">
    <polygon points="0,-16 0,-32 32,-32 32,0 16,0"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="3">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="0">
    <polygon points="0,0 -32,0 -32,32 0,32"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="4">
  <objectgroup draworder="index" id="2">
   <object id="1" x="16" y="0">
    <polygon points="0,0 -16,0 -16,32 0,32"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="5">
  <objectgroup draworder="index" id="2">
   <object id="1" x="24" y="8">
    <polygon points="0,0 -16,0 -16,16 0,16"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="6">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="0">
    <polygon points="0,0 -16,0 -16,32 0,32"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="7">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="16">
    <polygon points="0,0 16,-16 32,-16 32,0 16,16 0,16"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="8">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="32">
    <polygon points="0,-32 16,-32 32,-16 32,0 0,0"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="9">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="16">
    <polygon points="0,0 -32,0 -32,16 0,16"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="10">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="32">
    <polygon points="0,-16 16,-32 32,-32 32,0 0,0"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="11">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="0">
    <polygon points="0,0 0,16 16,32 32,32 32,16 16,0"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="12">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="16">
    <polygon points="0,0 -16,16 0,16"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="13">
  <objectgroup draworder="index" id="2">
   <object id="2" x="0" y="16">
    <polygon points="0,0 16,16 0,16"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="14">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="0">
    <polygon points="0,0 0,32 -32,32"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="15">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="32">
    <polygon points="0,0 -32,0 -32,-32"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="16">
  <objectgroup draworder="index" id="2">
   <object id="1" x="16" y="0">
    <polygon points="0,0 16,16 16,0"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="17">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="16">
    <polygon points="0,0 16,-16 0,-16"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="18">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="32">
    <polygon points="0,0 -32,-32 0,-32"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="19">
  <objectgroup draworder="index" id="2">
   <object id="1" x="32" y="0">
    <polygon points="0,0 -32,32 -32,0"/>
   </object>
  </objectgroup>
 </tile>
 <wangsets>
  <wangset name="Unnamed Set" type="mixed" tile="-1">
   <wangcolor name="Collision" color="#ff0000" tile="-1" probability="1"/>
   <wangtile tileid="0" wangid="1,1,1,0,1,1,1,1"/>
   <wangtile tileid="1" wangid="1,1,1,0,0,0,1,1"/>
   <wangtile tileid="2" wangid="1,1,1,1,1,0,1,1"/>
   <wangtile tileid="3" wangid="1,1,1,1,1,1,1,1"/>
   <wangtile tileid="4" wangid="1,0,0,0,1,1,1,1"/>
   <wangtile tileid="6" wangid="1,1,1,1,1,0,0,0"/>
   <wangtile tileid="7" wangid="1,1,1,0,1,1,1,0"/>
   <wangtile tileid="8" wangid="1,0,1,1,1,1,1,1"/>
   <wangtile tileid="9" wangid="0,0,1,1,1,1,1,0"/>
   <wangtile tileid="10" wangid="1,1,1,1,1,1,1,0"/>
   <wangtile tileid="11" wangid="1,0,1,1,1,0,1,1"/>
   <wangtile tileid="12" wangid="0,0,1,1,1,0,0,0"/>
   <wangtile tileid="13" wangid="0,0,0,0,1,1,1,0"/>
   <wangtile tileid="14" wangid="0,1,1,1,1,1,0,0"/>
   <wangtile tileid="15" wangid="0,0,0,1,1,1,1,1"/>
   <wangtile tileid="16" wangid="1,1,1,0,0,0,0,0"/>
   <wangtile tileid="17" wangid="1,0,0,0,0,0,1,1"/>
   <wangtile tileid="18" wangid="1,1,1,1,0,0,0,1"/>
   <wangtile tileid="19" wangid="1,1,0,0,0,1,1,1"/>
  </wangset>
 </wangsets>
</tileset>
