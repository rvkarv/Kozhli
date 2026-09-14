import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/lagna_calculator.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';

class EarthViewScreen extends StatefulWidget {
  const EarthViewScreen({super.key});
  @override State<EarthViewScreen> createState() => _EarthViewScreenState();
}

class _EarthViewScreenState extends State<EarthViewScreen> {
  late final WebViewController _controller;
  bool _ready=false, _loading=true;
  Map<String,dynamic>? _astro, _sunriseAstro;
  Timer? _timer;
  static const bg=Color(0xFF080808), panel=Color(0xFF141414), gold=Color(0xFFE8A83A), muted=Color(0xFFB5B5B5);

  @override void initState(){
    super.initState();
    _controller=WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(bg)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_){_ready=true;_refresh();}))
      ..loadFlutterAsset('assets/earth_view_bridge.html');
    _timer=Timer.periodic(const Duration(seconds:1),(_)=>_refresh());
  }
  @override void dispose(){_timer?.cancel();super.dispose();}

  DateTime _utc(AppState app){
    final loc=app.location, p=app.overridePickedLocal;
    if(loc==null||p==null)return DateTime.now().toUtc();
    final off=LocationService.effectiveOffset(loc,localDateTime:p);
    return DateTime.utc(p.year,p.month,p.day,p.hour,p.minute,p.second,p.millisecond,p.microsecond).subtract(off);
  }
  Future<Map<String,dynamic>?> _js(DateTime u) async{
    final iso=u.toIso8601String().replaceAll("'",r"\'");
    dynamic x=await _controller.runJavaScriptReturningResult("earthViewSnapshot('$iso')");
    if(x is String){x=jsonDecode(x);if(x is String)x=jsonDecode(x);}
    return x is Map?Map<String,dynamic>.from(x):null;
  }
  Future<void> _refresh() async{
    if(!_ready||!mounted)return;
    final app=context.read<AppState>();final loc=app.location;if(loc==null)return;
    try{
      final a=await _js(_utc(app));Map<String,dynamic>? s;
      final w=app.state;
      if(w!=null){
        final off=LocationService.effectiveOffset(loc,localDateTime:w.sunrise);
        final u=DateTime.utc(w.sunrise.year,w.sunrise.month,w.sunrise.day,w.sunrise.hour,w.sunrise.minute,w.sunrise.second).subtract(off);
        s=await _js(u);
      }
      if(mounted&&a!=null)setState((){_astro=a;_sunriseAstro=s;_loading=false;});
    }catch(_){ }
  }
  String _deg(double? x)=>x==null?'—':'${(x%360).toStringAsFixed(4)}°';
  String _boundary(String? iso,ResolvedLocation loc){
    final u=DateTime.tryParse(iso??'')?.toUtc();if(u==null)return'—';
    final l=u.add(LocationService.effectiveOffset(loc,utcNow:u));
    return '${l.year}-${l.month.toString().padLeft(2,'0')}-${l.day.toString().padLeft(2,'0')} ${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}:${l.second.toString().padLeft(2,'0')}';
  }
  String _date(DateTime u,ResolvedLocation l){final x=u.add(LocationService.effectiveOffset(l,utcNow:u));return '${x.year}-${x.month.toString().padLeft(2,'0')}-${x.day.toString().padLeft(2,'0')}';}

  @override Widget build(BuildContext c){
    final app=c.watch<AppState>(),loc=app.location,a=_astro;
    return Scaffold(backgroundColor:bg,appBar:AppBar(backgroundColor:bg,foregroundColor:Colors.white,title:const Text('பூமி பார்வை மையம் 0°',style:TextStyle(color:gold,fontWeight:FontWeight.w700)),actions:[
      IconButton(onPressed:app.useGps,icon:const Icon(Icons.gps_fixed,color:gold)),IconButton(onPressed:()=>_pick(app),icon:const Icon(Icons.schedule,color:gold))]),
      body:loc==null?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:()async{await app.useGps();await _refresh();},child:ListView(padding:const EdgeInsets.all(12),children:[
        _card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(loc.label,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),Text('Latitude ${loc.lat.toStringAsFixed(6)} • Longitude ${loc.lng.toStringAsFixed(6)}',style:const TextStyle(color:muted,fontSize:11)),Text(app.isLive?'LIVE GPS / தற்போதைய நேரம்':'PAST / FUTURE: ${app.overridePickedLocal}',style:const TextStyle(color:gold,fontSize:11))])),
        const SizedBox(height:10),if(_loading||a==null)_card(title:'வானியல் கணக்கு',child:const Padding(padding:EdgeInsets.all(20),child:Center(child:CircularProgressIndicator())))else ...[_tithi(app,loc,a),const SizedBox(height:10),_moon(app,a),const SizedBox(height:10),_lagna(_utc(app),loc),const SizedBox(height:10),_planets(a),const SizedBox(height:10),_sun(app),const SizedBox(height:10),_pakshi(a),const SizedBox(height:10),_thaarai(app)],
        const SizedBox(height:8),const Text('திதி/கிரக பாகைகள் Earth-centred (geocentric) கணக்கிலிருந்து; லக்னம் observer latitude/longitude அடிப்படையில்.',style:TextStyle(color:muted,fontSize:11))])));
  }
  Widget _tithi(AppState app,ResolvedLocation loc,Map<String,dynamic>a){
    final s=_sunriseAstro;final cur='${a['pakshaTamil']??'—'} ${a['tithiName']??'—'} (${a['tithiNumber']??'—'})';final sun=s==null?cur:'${s['pakshaTamil']??'—'} ${s['tithiName']??'—'} (${s['tithiNumber']??'—'})';
    return _card(title:'Civil Day vs திதிக்கான day',child:Column(children:[_line('Civil Day',_date(_utc(app),loc)),_line('திதிக்கான நாள் (சூரிய உதயம்)',sun),_line('Angular separation',_deg((a['angularSeparation']as num?)?.toDouble())),_line('திதி ஆரம்பம்',_boundary(a['tithiStartUtc']?.toString(),loc)),_line('திதி முடிவு',_boundary(a['tithiEndUtc']?.toString(),loc)),_line('அதிகார பட்சி / படு பட்சி','${a['adhikaraPakshi']??'—'} / ${a['paduPakshi']??'—'}'),_line('திதி கிரகம் / நாள்','${a['tithiRulerPlanet']??'—'} / ${a['tithiRulerDay']??'—'}')]));
  }
  Widget _moon(AppState app,Map<String,dynamic>a){final m=app.currentMoon;return _card(title:'Moon position — பூமியிலிருந்து',child:Column(children:[_line('Tropical longitude',_deg((a['moonLongitude']as num?)?.toDouble())),_line('Sidereal ராசி',m?.rasiName??'—'),_line('நட்சத்திரம் & பாதம்',m==null?'—':'${m.nakshatraName} • பாதம் ${m.pada}'),_line('Sidereal longitude',_deg(m?.siderealLongitude)),_line('Ayanamsa',_deg(m?.ayanamsa))]));}
  Widget _lagna(DateTime u,ResolvedLocation l){final x=LagnaCalculator.computeCurrent(utc:u,latitude:l.lat,longitudeEastPositive:l.lng);return _card(title:'லக்னம் — தற்போதைய நேரம்',child:Column(children:[_line('லக்ன ராசி',x.rasiName),_line('லக்ன நட்சத்திரம் & பாதம்','${x.nakshatraName} • பாதம் ${x.pada}')]));}
  Widget _planets(Map<String,dynamic>a){const n={'Sun':'சூரியன்','Moon':'சந்திரன்','Mercury':'புதன்','Venus':'சுக்கிரன்','Mars':'செவ்வாய்','Jupiter':'வியாழன்','Saturn':'சனி','Uranus':'யுரேனஸ்','Neptune':'நெப்டியூன்','Pluto':'புளூட்டோ'};final p=a['planets'];return _card(title:'கிரக / கோள்களின் Earth-centred longitude',child:Column(children:n.entries.map((e)=>_line(e.value,_deg((p is Map?(p[e.key]as num?):null)?.toDouble())).toList()));}
  Widget _sun(AppState app){final s=app.state;if(s==null)return _card(title:'சூரிய உதயம்',child:const Text('—'));String f(DateTime x)=>'${x.hour.toString().padLeft(2,'0')}:${x.minute.toString().padLeft(2,'0')}:${x.second.toString().padLeft(2,'0')}';return _card(title:'சூரிய நாள் — உதயம் முதல் மறுநாள் உதயம்',child:Column(children:[_line('இன்றைய சூரிய உதயம்',f(s.sunrise)),_line('இன்றைய சூரிய அஸ்தமனம்',f(s.sunset)),_line('மறுநாள் சூரிய உதயம்',f(s.nextSunrise))]));}
  Widget _pakshi(Map<String,dynamic>a){final rows=(a['fiveDayPakshi']as List?)?.cast<Map>()??const[];return _card(title:'5 நாள் — வளர்பிறை / தேய்பிறை பட்சி',child:Column(children:rows.map((r)=>_line('${r['day']}','வளர் ${r['valarpirai']} • தேய் ${r['theipirai']}')).toList()));}
  Widget _thaarai(AppState app){final r=app.thaarai,l=app.thaaraiLagna;return _card(title:'தாரா பலன் — தேர்ந்தெடுத்த பிறந்த நட்சத்திரம்',child:Column(children:[_line('ராசி நட்சத்திர தாரை',r==null?'பிறந்த நட்சத்திரம் அமைக்கவும்':'${r.category.name} (${r.ordinalFromBirth})'),_line('லக்ன நட்சத்திர தாரை',l==null?'பிறந்த லக்ன நட்சத்திரம் அமைக்கவும்':'${l.category.name} (${l.ordinalFromBirth})')]));}
  Widget _line(String k,String v)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(k,style:const TextStyle(color:muted,fontSize:12))),const SizedBox(width:8),Flexible(child:Text(v,textAlign:TextAlign.right,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600)))]));
  Widget _card({String? title,required Widget child})=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14),border:Border.all(color:gold.withOpacity(.22))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(title!=null)...[Text(title!,style:const TextStyle(color:gold,fontWeight:FontWeight.w700,fontSize:15)),const SizedBox(height:8)],child]));
  Future<void> _pick(AppState app)async{final n=app.overridePickedLocal??DateTime.now();final d=await showDatePicker(context:context,initialDate:n,firstDate:DateTime(1900),lastDate:DateTime(2200));if(d==null||!mounted)return;final t=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(n));if(t==null)return;app.setOverrideDateTime(DateTime(d.year,d.month,d.day,t.hour,t.minute));}
}
