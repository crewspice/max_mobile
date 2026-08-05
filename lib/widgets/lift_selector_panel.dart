import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/lift.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/device_config.dart';


class LiftSelectorColorScheme {
  final Color ball;
  final Color border;
  final Color selectedBorder;
  final Color shadow;
  final Color text;
  const LiftSelectorColorScheme({required this.ball,required this.border,required this.selectedBorder,required this.shadow,required this.text});
}

class LiftSelectorPanel extends StatefulWidget {
  final List<Lift>? lifts;
  final List<String>? serials;
  final String initialText;
  final ValueChanged<String> onChanged;
  final ValueChanged<Lift>? onLiftSelected;
  final LiftSelectorColorScheme colors;
  final bool readOnly;
  final double emptyTextSize;

  const LiftSelectorPanel({
    super.key,
    this.lifts,
    this.serials,
    this.initialText='',
    required this.onChanged,
    this.onLiftSelected,
    this.readOnly=false,
    this.emptyTextSize = 14,
    this.colors=const LiftSelectorColorScheme(
      ball:AppColors.yellow,
      border:AppColors.yellow,
      selectedBorder:AppColors.green,
      shadow:AppColors.main,
      text:AppColors.mainBackground,
    ),
  });

  @override
  State<LiftSelectorPanel> createState()=>_LiftSelectorPanelState();
}

class _LiftSelectorPanelState extends State<LiftSelectorPanel> {
  final TextEditingController _inputController=TextEditingController();
  final FocusNode _focusNode=FocusNode();
  final Random _random=Random();
  final List<double> _latitudes=[];
  String _serial='';
  bool _liftSelected=false;
  bool _showSuggestions=false;

  bool get isLiftMode=>widget.lifts!=null;

  double _scale = 1.0;

  @override
  void initState(){
    super.initState();
    _serial = widget.initialText;
    _inputController.text = _serial;

    if(!widget.readOnly){
      _inputController.addListener(_onInput);
      _focusNode.addListener((){
        setState((){
          _showSuggestions =
              _focusNode.hasFocus &&
              !_liftSelected &&
              _serial.isNotEmpty;
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final screenWidth = MediaQuery.of(context).size.width;
    _scale = (screenWidth / 390).clamp(0.85, 1.8);

    _syncLatitudes();
  }

  @override
  void didUpdateWidget(covariant LiftSelectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialText != widget.initialText) {
      setState(() {
        _serial = widget.initialText;
        _inputController.text = widget.initialText;
        _liftSelected = widget.readOnly;
        _syncLatitudes();
      });
    }

    if (oldWidget.readOnly != widget.readOnly) {
      setState(() {});
    }
  }

  double _getScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / 390).clamp(0.85, 1.8);
  }

  void _onInput(){
    if(widget.readOnly)return;
    if(_inputController.text==_serial)return;
    setState((){
      _serial=_inputController.text;
      _liftSelected=false;
      _showSuggestions=_focusNode.hasFocus&&_serial.isNotEmpty;
      _syncLatitudes();
    });
    widget.onChanged(_serial);
    _checkLift();
  }

  void _checkLift(){
    if(!isLiftMode)return;
    final match=widget.lifts!.where((l)=>(l.serialNumber??'').toLowerCase()==_serial.toLowerCase());
    if(match.isNotEmpty)_selectLift(match.first);
  }

  void _selectLift(Lift lift){
    setState((){
      _serial=lift.serialNumber??'';
      _inputController.text=_serial;
      _liftSelected=true;
      _showSuggestions=false;
      _syncLatitudes();
    });
    widget.onChanged(_serial);
    widget.onLiftSelected?.call(lift);
    _focusNode.unfocus();
  }

  void _setSerial(String serial){
    setState((){
      _serial=serial;
      _inputController.text=serial;
      _liftSelected=true;
      _showSuggestions=false;
      _syncLatitudes();
    });
    widget.onChanged(serial);
    _focusNode.unfocus();
  }

  void _syncLatitudes(){
    while(_latitudes.length<_serial.length){
      _latitudes.add(
        (_random.nextDouble()*10-5) * _scale,
      );
    }

    if(_latitudes.length>_serial.length){
      _latitudes.removeRange(_serial.length,_latitudes.length);
    }
  }

  Iterable<dynamic> get suggestions{
    final q=_serial.toLowerCase();
    if(q.isEmpty)return const [];
    if(isLiftMode)return widget.lifts!.where((l)=>(l.serialNumber??'').toLowerCase().contains(q));
    return (widget.serials??[]).where((s)=>s.toLowerCase().contains(q));
  }

  double selectorWidth(BuildContext context) {
    final scale = _getScale(context);
    if (_serial.isNotEmpty) {
      return ((_serial.length * 38) + 24) * scale;
    }
    return MediaQuery.of(context).size.width * 0.40;
  }

  @override
  void dispose(){
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  BoxDecoration _gradientGlow() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.green.withOpacity(.45),
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ],
    );
  }

  Color _gradientColorAt(double x) {
    if (x <= .5) {
      return Color.lerp(
        AppColors.yellow,
        AppColors.green,
        x * 2,
      )!;
    }
    return Color.lerp(
      AppColors.green,
      AppColors.red,
      (x - .5) * 2,
    )!;
  }

  @override
  Widget build(BuildContext context){
    final suggestionList=suggestions.toList();
    final width = selectorWidth(context);
    final scale = _getScale(context);
    final selectorHeight = 50 * scale;
    final ballSize = 32 * scale;
    final characterSize = ballSize * 0.93;

    return Column(
      children:[
        GestureDetector(
          behavior:HitTestBehavior.opaque,
          onTap: widget.readOnly
              ? null
              : ()=>_focusNode.requestFocus(),
          child:SizedBox(
            width:width,
            height:selectorHeight,
            child:Stack(
              alignment:Alignment.center,
              children:[
                AnimatedContainer(
                  duration:const Duration(milliseconds:250),
                  width:width+20,
                  height:selectorHeight * 1.2,
                  decoration:_serial.isEmpty
                      ? BoxDecoration(
                          borderRadius:BorderRadius.circular(16),
                          gradient:const LinearGradient(
                            begin:Alignment.centerLeft,
                            end:Alignment.centerRight,
                            colors:[
                              AppColors.yellow,
                              AppColors.green,
                              AppColors.red,
                            ],
                          ),
                        )
                      : const BoxDecoration(),
                ),
                Container(
                  width:width,
                  height:selectorHeight,
                  decoration:BoxDecoration(
                    borderRadius:BorderRadius.circular(12),
                    color:_serial.isEmpty
                        ? AppColors.mainBackground.withOpacity(.85)
                        : AppColors.mainBackground,
                    border:_serial.isEmpty
                        ? Border.all(color:widget.colors.border,width:.3)
                        : null,
                  ),
                  child:_serial.isEmpty
                    ? Center(
                        child: MediaQuery.withNoTextScaling(
                          child: Text(
                            'Enter Serial',
                            style: TextStyle(
                              color: widget.colors.border,
                              fontSize: DeviceConfig.device == "ipad"
                                  ? 26
                                  : widget.emptyTextSize,
                            ),
                          ),
                        ),
                      )
                      : Row(
                          mainAxisAlignment:MainAxisAlignment.center,
                          children:[
                            for(int i=0;i<_serial.length;i++)
                              TweenAnimationBuilder<double>(
                                key:ValueKey('${_serial[i]}_$i'),
                                tween:Tween<double>(begin:1.6,end:0),
                                duration:const Duration(milliseconds:1350),
                                curve:Curves.elasticOut,
                                builder:(context,value,child)=>Transform.translate(
                                  offset: Offset(
                                    value * 45 * scale,
                                    _latitudes[i] * scale,
                                  ),
                                  child:Transform.rotate(angle:value*.15,child:child),
                                ),
                                child:Container(
                                  margin: const EdgeInsets.symmetric(horizontal:3),
                                  child:Stack(
                                    alignment:Alignment.center,
                                    children:[
                                      AnimatedContainer(
                                        duration:const Duration(milliseconds:250),
                                        width:ballSize,
                                        height:ballSize,
                                        decoration:BoxDecoration(
                                          color:widget.colors.ball,
                                          shape:BoxShape.circle,
                                          boxShadow:[
                                            BoxShadow(
                                              color:_gradientColorAt(
                                                _serial.length<=1
                                                  ? .5
                                                  : i/(_serial.length-1),
                                              ).withOpacity(.85),
                                              blurRadius:_liftSelected?4:2,
                                              spreadRadius:_liftSelected?2:1,
                                            ),
                                          ],
                                        ),
                                        child:Center(
                                          child:Transform.translate(
                                            offset: Offset(
                                              0,
                                              -ballSize * 0.12,
                                            ),
                                            child: MediaQuery.withNoTextScaling(
                                              child: Text(
                                                _serial[i],
                                                style: GoogleFonts.knewave(
                                                  color: widget.colors.text,
                                                  fontSize: characterSize * .85,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                if(!widget.readOnly)
                  Opacity(
                    opacity:0,
                    child:EditableText(
                    controller:_inputController,
                    focusNode:_focusNode,
                    keyboardType:TextInputType.number,
                    textInputAction:TextInputAction.done,
                    style:const TextStyle(fontSize:1),
                    cursorColor:Colors.transparent,
                    backgroundCursorColor:Colors.transparent,
                    onChanged:(_){},
                  ),
                ),
              ],
            ),
          ),
        ),
        if(!widget.readOnly && _showSuggestions && suggestionList.isNotEmpty)
          ConstrainedBox(
            constraints:const BoxConstraints(maxHeight:250),
            child:Container(
              margin:const EdgeInsets.only(top:8),
              decoration:BoxDecoration(
                color:AppColors.main,
                borderRadius:BorderRadius.circular(12),
              ),
              child:ListView.builder(
                shrinkWrap:true,
                padding:EdgeInsets.zero,
                itemCount:suggestionList.length,
                itemBuilder:(_,i){
                  final item=suggestionList[i];
                  return ListTile(
                    dense:true,
                    visualDensity:VisualDensity.compact,
                    title:Text(
                      item is Lift?item.serialNumber??'':item,
                      style:TextStyle(color:widget.colors.border),
                    ),
                    subtitle:item is Lift
                        ? Text(
                            item.model??'',
                            style:TextStyle(color:widget.colors.border),
                          )
                        : null,
                    onTap:()=>item is Lift?_selectLift(item):_setSerial(item),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}