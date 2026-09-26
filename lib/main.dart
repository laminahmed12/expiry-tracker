import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'screens/license_gate.dart';

void main() => runApp(const AdreemkApp());

class Product {
  final String id, name, barcode, category;
  final DateTime expiry;
  final int quantity;
  const Product({required this.id, required this.name, required this.barcode, required this.expiry, required this.quantity, required this.category});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'barcode':barcode,'expiry':expiry.toIso8601String(),'quantity':quantity,'category':category};
  factory Product.fromJson(Map<String,dynamic> j)=>Product(
    id:j['id'],name:j['name'],barcode:j['barcode']??'',expiry:DateTime.parse(j['expiry']),
    quantity:j['quantity']??0,category:j['category']??'عام');
}

class Store {
  static const key='adreemk_products_v1';
  static Future<List<Product>> load() async {
    final p=await SharedPreferences.getInstance(), raw=p.getString(key);
    if(raw==null)return [];
    return (jsonDecode(raw) as List).map((e)=>Product.fromJson(e)).toList();
  }
  static Future<void> save(List<Product> items) async {
    final p=await SharedPreferences.getInstance();
    await p.setString(key,jsonEncode(items.map((e)=>e.toJson()).toList()));
  }
}

class AdreemkApp extends StatelessWidget {
  const AdreemkApp({super.key});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'ADREEMK | صلاحيات المواد',
    theme:ThemeData(useMaterial3:true,fontFamily:'sans',scaffoldBackgroundColor:const Color(0xfff7f8f6),
      colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff174d3a))),
    home:const LicenseGate(child: Home()));
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState()=>_HomeState(); }
class _HomeState extends State<Home> {
  int tab=0,taps=0; bool loading=true; List<Product> items=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{items=await Store.load();if(mounted)setState(()=>loading=false);}
  Future<void> save(Product p)async{setState(()=>items=[...items,p]);await Store.save(items);}
  Future<void> remove(Product p)async{setState(()=>items.removeWhere((x)=>x.id==p.id));await Store.save(items);}
  void adminTap()async{taps++;if(taps<3)return;taps=0;
    final v=await showDialog(context:context,builder:(_)=>const Gate());
    if(v=='116936'&&mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>const Admin()));
  }
  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final pages=[
      Dashboard(items:items,onAdmin:adminTap),
      Inventory(items:items,onAdd:save,onDelete:remove),
      Alerts(items:items),const Settings()];
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:GestureDetector(onTap:adminTap,child:const Text('ADREEMK',style:TextStyle(fontWeight:FontWeight.w900))),
        actions:[IconButton(icon:const Icon(Icons.qr_code_scanner),onPressed:()async{
          final v=await Navigator.push<String>(context,MaterialPageRoute(builder:(_)=>const Scanner()));
          if(v!=null&&mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('الباركود: '+v)));
        })]),
      body:pages[tab],
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'الرئيسية'),
        NavigationDestination(icon:Icon(Icons.inventory_2_outlined),selectedIcon:Icon(Icons.inventory_2),label:'المواد'),
        NavigationDestination(icon:Icon(Icons.notifications_none),selectedIcon:Icon(Icons.notifications),label:'التنبيهات'),
        NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'الإعدادات')]));
  }
}

class Dashboard extends StatelessWidget{
  final List<Product> items; final VoidCallback onAdmin;
  const Dashboard({super.key,required this.items,required this.onAdmin});
  @override Widget build(BuildContext c){
    final near=items.where((p){final d=p.expiry.difference(DateTime.now()).inDays;return d>=0&&d<=30;}).length;
    final expired=items.where((p)=>p.expiry.isBefore(DateTime.now())).length;
    return ListView(padding:const EdgeInsets.all(18),children:[
      const Text('لوحة التحكم',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),const Text('إدارة المواد وتواريخ الصلاحية بطريقة بسيطة.'),
      const SizedBox(height:20),Wrap(spacing:10,runSpacing:10,children:[
        Stat('إجمالي المواد',items.length,Icons.inventory_2),
        Stat('قريبة الانتهاء',near,Icons.schedule),
        Stat('منتهية',expired,Icons.warning_amber_rounded)]),
      const SizedBox(height:20),Card(elevation:0,child:ListTile(
        leading:const Icon(Icons.verified_user_outlined),title:const Text('ADREEMK'),
        subtitle:const Text('تشغيل محلي + نظام ترخيص قابل للربط بالخادم.'),
        trailing:IconButton(onPressed:onAdmin,icon:const Icon(Icons.more_horiz))));]);
  }
}
class Stat extends StatelessWidget{final String title;final int value;final IconData icon;const Stat(this.title,this.value,this.icon,{super.key});
@override Widget build(BuildContext c)=>SizedBox(width:170,child:Card(elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
Icon(icon),const SizedBox(height:10),Text(value.toString(),style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),Text(title)]))));}

class Inventory extends StatefulWidget{
 final List<Product> items;final Future<void> Function(Product) onAdd,onDelete;
 const Inventory({super.key,required this.items,required this.onAdd,required this.onDelete});
 @override State<Inventory> createState()=>_InventoryState();
}
class _InventoryState extends State<Inventory>{
 String q='';
 @override Widget build(BuildContext c){final list=widget.items.where((p)=>p.name.contains(q)||p.barcode.contains(q)).toList();
 return Column(children:[
  Padding(padding:const EdgeInsets.all(12),child:TextField(onChanged:(v)=>setState(()=>q=v),
    decoration:InputDecoration(hintText:'ابحث عن مادة أو باركود',prefixIcon:const Icon(Icons.search),filled:true,
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none)))),
  Expanded(child:list.isEmpty?const Center(child:Text('لا توجد مواد بعد')):ListView.builder(itemCount:list.length,itemBuilder:(_,i){
    final p=list[i],d=p.expiry.difference(DateTime.now()).inDays;
    return Card(elevation:0,child:ListTile(leading:Icon(d<0?Icons.error_outline:Icons.inventory_2_outlined),
      title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Text('الكمية: '+p.quantity.toString()+' • الانتهاء: '+p.expiry.day.toString()+'/'+p.expiry.month.toString()+'/'+p.expiry.year.toString()),
      trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>widget.onDelete(p))));
  })),
  Padding(padding:const EdgeInsets.all(16),child:FilledButton.icon(icon:const Icon(Icons.add),label:const Text('إضافة مادة'),
    onPressed:()async{final p=await Navigator.push<Product>(c,MaterialPageRoute(builder:(_)=>const AddProduct()));if(p!=null)await widget.onAdd(p);}))
 ]);}
}

class AddProduct extends StatefulWidget{const AddProduct({super.key});@override State<AddProduct> createState()=>_AddProductState();}
class _AddProductState extends State<AddProduct>{
 final name=TextEditingController(),barcode=TextEditingController(),qty=TextEditingController(text:'1');
 DateTime expiry=DateTime.now().add(const Duration(days:30));String category='عام';
 @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('إضافة مادة')),
 body:ListView(padding:const EdgeInsets.all(18),children:[
 TextField(controller:name,decoration:const InputDecoration(labelText:'اسم المادة')),const SizedBox(height:12),
 TextField(controller:barcode,decoration:const InputDecoration(labelText:'الباركود')),const SizedBox(height:12),
 TextField(controller:qty,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الكمية')),const SizedBox(height:12),
 DropdownButtonFormField<String>(value:category,items:['عام','غذائي','دوائي','مواد خام','أخرى'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>category=v??'عام'),decoration:const InputDecoration(labelText:'التصنيف')),
 ListTile(contentPadding:EdgeInsets.zero,title:const Text('تاريخ الانتهاء'),subtitle:Text('اضغط لاختيار التاريخ'),onTap:()async{
  final d=await showDatePicker(context:c,initialDate:expiry,firstDate:DateTime.now(),lastDate:DateTime(2100));if(d!=null)setState(()=>expiry=d);}),
 const SizedBox(height:20),FilledButton(onPressed:()=>Navigator.pop(c,Product(id:DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),barcode:barcode.text.trim(),expiry:expiry,quantity:int.tryParse(qty.text)??1,category:category)),child:const Text('حفظ المادة'))
 ]));
}

class Alerts extends StatelessWidget{final List<Product> items;const Alerts({super.key,required this.items});
@override Widget build(BuildContext c){final a=items.where((p)=>p.expiry.difference(DateTime.now()).inDays<=30).toList();
return ListView(padding:const EdgeInsets.all(18),children:[const Text('التنبيهات',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:16),
if(a.isEmpty)const Card(child:ListTile(title:Text('لا توجد تنبيهات حالية'))),
...a.map((p){final d=p.expiry.difference(DateTime.now()).inDays;return Card(elevation:0,child:ListTile(
leading:Icon(d<0?Icons.error:Icons.schedule),title:Text(p.name),subtitle:Text(d<0?'منتهية':'متبقي '+d.toString()+' يوم')));})]);}}
class Settings extends StatelessWidget{const Settings({super.key});
@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[
const Text('الإعدادات',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:14),
const Card(elevation:0,child:Column(children:[
ListTile(leading:Icon(Icons.backup_outlined),title:Text('النسخ الاحتياطي'),subtitle:Text('محليًا، مع تجهيز الربط بالنسخ والاستعادة.')),
Divider(height:1),ListTile(leading:Icon(Icons.verified_outlined),title:Text('الترخيص'),subtitle:Text('7 أيام تجربة • 6 أشهر • سنة • دائم')),
Divider(height:1),ListTile(leading:Icon(Icons.help_outline),title:Text('المساعدة'),subtitle:Text('دليل الاستخدام والدعم.'))]))]);}

class Scanner extends StatelessWidget{const Scanner({super.key});
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('مسح الباركود')),
body:MobileScanner(onDetect:(capture){final b=capture.barcodes.isEmpty?null:capture.barcodes.first.rawValue;if(b!=null&&b.isNotEmpty)Navigator.pop(c,b);}));
}

class Gate extends StatefulWidget{const Gate({super.key});@override State<Gate> createState()=>_GateState();}
class _GateState extends State<Gate>{final x=TextEditingController();
@override Widget build(BuildContext c)=>AlertDialog(title:const Text('دخول الإدارة'),content:TextField(controller:x,obscureText:true,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رمز الإدارة')),
actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,x.text),child:const Text('دخول'))]);}

class Admin extends StatefulWidget{const Admin({super.key});@override State<Admin> createState()=>_AdminState();}
class _AdminState extends State<Admin>{final code=TextEditingController();String plan='6_months',status='جاهز للربط بالخادم';
@override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('ADREEMK • الإدارة')),
body:ListView(padding:const EdgeInsets.all(18),children:[
const Text('إدارة التراخيص',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:8),
const Text('الإدارة النهائية للتراخيص ستكون عبر Cloudflare Worker + D1.'),
const SizedBox(height:20),DropdownButtonFormField<String>(value:plan,items:const[
DropdownMenuItem(value:'6_months',child:Text('6 أشهر')),DropdownMenuItem(value:'year',child:Text('سنة')),DropdownMenuItem(value:'permanent',child:Text('دائم'))],
onChanged:(v)=>setState(()=>plan=v??'6_months'),decoration:const InputDecoration(labelText:'نوع الترخيص')),
const SizedBox(height:12),TextField(controller:code,decoration:const InputDecoration(labelText:'كود التفعيل')),
const SizedBox(height:12),FilledButton(onPressed:()=>setState(()=>status=code.text.trim().isEmpty?'أدخل كود التفعيل':'تم حفظ الكود محليًا — بانتظار ربط الخادم'),child:const Text('حفظ')),
const SizedBox(height:12),Text(status)]));}
}