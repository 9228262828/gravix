import 'package:flutter/material.dart';
const voidC=Color(0xFF050814), panel=Color(0xFF101A30), cyan=Color(0xFF51F3FF), purple=Color(0xFF9C63FF), orange=Color(0xFFFFA043), red=Color(0xFFFF466D), green=Color(0xFF63FFAE), muted=Color(0xFF8293B2);
class NeonTitle extends StatelessWidget { final String text; final double size; const NeonTitle(this.text,{super.key,this.size=34});
 @override Widget build(BuildContext c)=>Text(text,style:TextStyle(fontSize:size,fontWeight:FontWeight.w900,letterSpacing:2,color:Colors.white,shadows:const[Shadow(color:cyan,blurRadius:18)]));}
class GButton extends StatelessWidget {final String text;final IconData icon;final VoidCallback? tap;final Color color;const GButton(this.text,this.icon,this.tap,{super.key,this.color=cyan});
 @override Widget build(BuildContext c)=>SizedBox(height:56,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:color,foregroundColor:voidC),onPressed:tap,icon:Icon(icon),label:Text(text,style:const TextStyle(fontWeight:FontWeight.w900))));}
