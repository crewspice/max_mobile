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

  // Dispatch stamps this sentinel when the customer had no preference between
  // interchangeable units; only ever surfaces in read-only panels.
  bool get _isNoPreference=>widget.readOnly&&_serial.trim()=='noPref';

  static const _noPreferenceWord1='No';
  static const _noPreferenceWord2Full='Preference';
  static const _noPreferenceWord2Short='Pref.';
  String get _noPreferenceWord2=>
      DeviceConfig.isIphone?_noPreferenceWord2Short:_noPreferenceWord2Full;
  int get _noPreferenceLength=>_noPreferenceWord1.length+_noPreferenceWord2.length;

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

  // iOS "Bold Text" accessibility setting makes Flutter's Text widget
  // silently merge FontWeight.bold onto every style, which fights the
  // hand-tuned stroke/fill look of the character balls. Force it off here,
  // the same way MediaQuery.withNoTextScaling neutralizes larger-text.
  Widget _noAccessibilityTextStyling({required Widget child}) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
        boldText: false,
      ),
      child: child,
    );
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
    if(_serial.isEmpty)_focusNode.unfocus();
  }

  void _checkLift(){
    if(!isLiftMode)return;
    if(_serial.isEmpty)return;
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
    final length=_isNoPreference?_noPreferenceLength:_serial.length;
    while(_latitudes.length<length){
      _latitudes.add(
        (_random.nextDouble()*10-5) * _scale,
      );
    }

    if(_latitudes.length>length){
      _latitudes.removeRange(length,_latitudes.length);
    }
  }

  String _serialOf(dynamic item)=>item is Lift?(item.serialNumber??''):item as String;

  // Prefix matches ("begins with") come before mid/end matches; within each
  // group, numeric serials sort smallest-to-largest.
  List<dynamic> get suggestions{
    final q=_serial.toLowerCase();
    if(q.isEmpty)return const [];
    final source=isLiftMode?widget.lifts!:(widget.serials??[]);
    final matches=source.where((item)=>_serialOf(item).toLowerCase().contains(q)).toList();

    int compareWithinGroup(dynamic a,dynamic b){
      final ai=int.tryParse(_serialOf(a));
      final bi=int.tryParse(_serialOf(b));
      if(ai!=null&&bi!=null)return ai.compareTo(bi);
      if(ai!=null)return -1;
      if(bi!=null)return 1;
      return _serialOf(a).compareTo(_serialOf(b));
    }

    final starts=matches.where((item)=>_serialOf(item).toLowerCase().startsWith(q)).toList()
      ..sort(compareWithinGroup);
    final rest=matches.where((item)=>!_serialOf(item).toLowerCase().startsWith(q)).toList()
      ..sort(compareWithinGroup);

    return [...starts,...rest];
  }

  double selectorWidth(BuildContext context) {
    final scale = _getScale(context);
    if (_isNoPreference) {
      return ((_noPreferenceLength * 38) + 24) * scale;
    }
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

  // Text centers on the font's line box, not glyph ink, so short x-height
  // lowercase letters (no ascender) sit visibly lower in the ball than
  // digits/caps/ascender letters and need a bigger upward correction.
  double _charVerticalNudge(String char) {
    const xHeightOnly = 'acemnorsuvwxz.';
    return xHeightOnly.contains(char) ? -0.34 : -0.24;
  }

  Widget _buildBall({
    required String char,
    required int index,
    required int totalLength,
    required double ballSize,
    required double characterFontSize,
    required double scale,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${char}_$index'),
      tween: Tween<double>(begin: 1.6, end: 0),
      duration: const Duration(milliseconds: 1350),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(
          value * 45 * scale,
          _latitudes[index] * scale,
        ),
        child: Transform.rotate(angle: value * .15, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: ballSize,
              height: ballSize,
              decoration: BoxDecoration(
                color: widget.colors.ball,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gradientColorAt(
                      totalLength <= 1 ? .5 : index / (totalLength - 1),
                    ).withOpacity(.85),
                    blurRadius: _liftSelected ? 4 : 2,
                    spreadRadius: _liftSelected ? 2 : 1,
                  ),
                ],
              ),
              child: Center(
                child: Transform.translate(
                  offset: Offset(
                    0,
                    characterFontSize * _charVerticalNudge(char),
                  ),
                  child: _noAccessibilityTextStyling(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          char,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.knewave(
                            fontSize: characterFontSize,
                          ).copyWith(
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = ballSize * 0.16
                              ..color = widget.colors.ball,
                          ),
                        ),
                        Text(
                          char,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.knewave(
                            color: widget.colors.text,
                            fontSize: characterFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordBalls({
    required String word,
    required int indexOffset,
    required int totalLength,
    required double ballSize,
    required double characterFontSize,
    required double scale,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < word.length; i++)
          _buildBall(
            char: word[i],
            index: indexOffset + i,
            totalLength: totalLength,
            ballSize: ballSize,
            characterFontSize: characterFontSize,
            scale: scale,
          ),
      ],
    );
  }

  Widget _buildSuggestionPill(dynamic item){
    final label=_serialOf(item);
    return Material(
      color:Colors.transparent,
      child:InkWell(
        borderRadius:BorderRadius.circular(20),
        onTap:()=>item is Lift?_selectLift(item):_setSerial(item),
        child:Container(
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
          decoration:BoxDecoration(
            color:AppColors.mainBackground.withOpacity(.12),
            borderRadius:BorderRadius.circular(20),
            border:Border.all(color:widget.colors.border,width:1),
          ),
          alignment:Alignment.center,
          child:Text(
            label,
            textAlign:TextAlign.center,
            overflow:TextOverflow.ellipsis,
            style:TextStyle(color:widget.colors.border,fontSize:18,fontWeight:FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    final suggestionList=suggestions.toList();
    final width = selectorWidth(context);
    final scale = _getScale(context);
    final selectorHeight = 50 * scale;
    final ballSize = 32 * scale;
    final characterSize = ballSize * 0.93;
    final characterFontSize = characterSize * 1.0;

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
              clipBehavior:Clip.none,
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
                        child: _noAccessibilityTextStyling(
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
                      : _isNoPreference
                      ? Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildWordBalls(
                                word: _noPreferenceWord1,
                                indexOffset: 0,
                                totalLength: _noPreferenceLength,
                                ballSize: ballSize,
                                characterFontSize: characterFontSize,
                                scale: scale,
                              ),
                              SizedBox(width: ballSize * 0.5),
                              _buildWordBalls(
                                word: _noPreferenceWord2,
                                indexOffset: _noPreferenceWord1.length,
                                totalLength: _noPreferenceLength,
                                ballSize: ballSize,
                                characterFontSize: characterFontSize,
                                scale: scale,
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment:MainAxisAlignment.center,
                          children:[
                            for(int i=0;i<_serial.length;i++)
                              _buildBall(
                                char: _serial[i],
                                index: i,
                                totalLength: _serial.length,
                                ballSize: ballSize,
                                characterFontSize: characterFontSize,
                                scale: scale,
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
          Center(
            child:ConstrainedBox(
              constraints:BoxConstraints(
                maxHeight:250,
                maxWidth:MediaQuery.of(context).size.width * 0.6,
              ),
              child:Container(
                margin:const EdgeInsets.only(top:8),
                padding:const EdgeInsets.all(8),
                child:SingleChildScrollView(
                  child:Column(
                    mainAxisSize:MainAxisSize.min,
                    children:[
                      for(int i=0;i<suggestionList.length;i+=2)
                        Padding(
                          padding:const EdgeInsets.symmetric(vertical:4),
                          child:Row(
                            crossAxisAlignment:CrossAxisAlignment.start,
                            children:[
                              Expanded(child:_buildSuggestionPill(suggestionList[i])),
                              const SizedBox(width:8),
                              Expanded(
                                child:i+1<suggestionList.length
                                    ?_buildSuggestionPill(suggestionList[i+1])
                                    :const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}