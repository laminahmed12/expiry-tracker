import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'licensing_api.dart';

class LicenseState {
  final bool active; final bool trial; final int daysLeft; final String plan; final DateTime? expiresAt;
  const LicenseState({required this.active, required this.trial, required this.daysLeft, required this.plan, this.expiresAt});
}

class LicenseService {
  static const trialKey='adreemk_trial_started_v2';
  static const licenseKey='adreemk_license_v2';
  static const lastCheckKey='adreemk_last_online_check_v2';
  static const deviceKey='adreemk_device_id_v1';
  static const graceHours=72;

  static Future<String> deviceId() async {
    final p=await SharedPreferences.getInstance();
    final existing=p.getString(deviceKey);
    if(existing!=null&&existing.isNotEmpty)return existing;
    final r=Random.secure();
    final id=List.generate(16,(_)=>r.nextInt(256).toRadixString(16).padLeft(2,'0')).join();
    await p.setString(deviceKey,id); return id;
  }

  static Future<LicenseState> status() async {
    final p=await SharedPreferences.getInstance();
    final raw=p.getString(licenseKey);
    if(raw!=null){
      try {
        final data=jsonDecode(raw) as Map<String,dynamic>;
        final permanent=data['permanent']==true;
        final exp=data['expiresAt']==null?null:DateTime.tryParse(data['expiresAt'].toString());
        if(permanent)return const LicenseState(active:true,trial:false,daysLeft:999999,plan:'permanent');
        if(exp!=null&&DateTime.now().isBefore(exp))return LicenseState(active:true,trial:false,daysLeft:daysUntil(exp),plan:data['plan']??'6_months',expiresAt:exp);
      } catch(_){ }
    }
    final start=await trialStart();
    final left=7-DateTime.now().difference(start).inDays;
    if(left>0)return LicenseState(active:true,trial:true,daysLeft:left,plan:'trial',expiresAt:start.add(const Duration(days:7)));
    return const LicenseState(active:false,trial:false,daysLeft:0,plan:'expired');
  }

  static Future<DateTime> trialStart() async {
    final p=await SharedPreferences.getInstance(); final raw=p.getString(trialKey);
    if(raw!=null)return DateTime.parse(raw);
    final now=DateTime.now(); await p.setString(trialKey,now.toIso8601String()); return now;
  }
  static int daysUntil(DateTime d){final diff=d.difference(DateTime.now());return diff.isNegative?0:diff.inHours~/24+1;}
  static Future<void> saveLicense(Map<String,dynamic> data) async {final p=await SharedPreferences.getInstance();await p.setString(licenseKey,jsonEncode(data));await p.setString(lastCheckKey,DateTime.now().toIso8601String());}
  static Future<bool> graceValid() async {final p=await SharedPreferences.getInstance();final raw=p.getString(lastCheckKey);if(raw==null)return false;final d=DateTime.tryParse(raw);return d!=null&&DateTime.now().difference(d).inHours<=graceHours;}

  static Future<void> activateFromServer(String code) async {
    final id=await deviceId();
    final result=await LicensingApi().activate(code:code,deviceId:id);
    final license=Map<String,dynamic>.from(result['license'] as Map);
    await saveLicense({'code':code,'plan':license['plan'],'permanent':license['permanent']==true,'expiresAt':license['expiresAt'],'deviceId':id,'serverVerified':true});
  }

  static Future<bool> refreshFromServer() async {
    final id=await deviceId();
    try {
      final result=await LicensingApi().checkLicense(id);
      final license=Map<String,dynamic>.from(result['license'] as Map);
      await saveLicense({'code':'server','plan':license['plan'],'permanent':license['permanent']==true,'expiresAt':license['expiresAt'],'deviceId':id,'serverVerified':true});
      return true;
    } catch(_){return false;}
  }
}