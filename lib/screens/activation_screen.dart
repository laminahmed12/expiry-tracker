import 'package:flutter/material.dart';
import '../services/license_service.dart';
import '../services/licensing_api.dart';

class ActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;
  const ActivationScreen({super.key,required this.onActivated});
  @override State<ActivationScreen> createState()=>_ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final code=TextEditingController(); String? error; bool loading=false;

  Future<void> activate() async {
    final value=code.text.trim().toUpperCase();
    if(value.isEmpty){setState(()=>error='أدخل كود التفعيل');return;}
    setState((){loading=true;error=null;});
    try {
      await LicenseService.activateFromServer(value);
      if(!mounted)return;
      widget.onActivated(); Navigator.pop(context);
    } on LicensingException catch(e) {
      if(mounted)setState(()=>error=e.message);
    } catch(_) {
      if(mounted)setState(()=>error='تعذر الاتصال بخادم التفعيل. تحقق من الإنترنت وحاول مرة أخرى.');
    } finally {
      if(mounted)setState(()=>loading=false);
    }
  }

  @override Widget build(BuildContext context)=>Directionality(
    textDirection:TextDirection.rtl,
    child:Scaffold(
      appBar:AppBar(title:const Text('تفعيل ADREEMK')),
      body:ListView(padding:const EdgeInsets.all(22),children:[
        const Icon(Icons.verified_user_outlined,size:64),
        const SizedBox(height:18),
        const Text('أدخل كود التفعيل',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        const Text('سيتم التحقق من الكود وربطه بهذا الجهاز عبر خادم الترخيص.'),
        const SizedBox(height:24),
        TextField(controller:code,textCapitalization:TextCapitalization.characters,
          decoration:InputDecoration(labelText:'كود التفعيل',hintText:'AD6-XXXXXXXX',errorText:error,prefixIcon:const Icon(Icons.key),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)))),
        const SizedBox(height:18),
        FilledButton(onPressed:loading?null:activate,child:loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('تفعيل الآن')),
      ]),
    ),
  );
}