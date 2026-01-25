<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.0" name="Castle Indoor" tilewidth="32" tileheight="32" tilecount="256" columns="16">
 <image source="castle-indoor.png" width="512" height="512"/>
 <tile id="224">
  <properties>
   <property name="custom" value="LightSource"/>
   <property name="light_color" value="FFD28DFF"/>
   <property name="light_offset" type="int" value="24"/>
   <property name="light_radius" type="int" value="128"/>
  </properties>
  <animation>
   <frame tileid="224" duration="100"/>
   <frame tileid="225" duration="100"/>
   <frame tileid="226" duration="100"/>
  </animation>
 </tile>
</tileset>
