import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlutterTtsPage extends StatefulWidget {
  const FlutterTtsPage({super.key});

  @override
  State<FlutterTtsPage> createState() => _FlutterTtsPageState();
}

class _FlutterTtsPageState extends State<FlutterTtsPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController(
    text: '안녕하세요. flutter_tts 보이스 테스트입니다.',
  );

  List<String> _languages = <String>[];
  List<Map<String, dynamic>> _voices = <Map<String, dynamic>>[];

  String? _selectedLanguage;
  int? _selectedVoiceIndex;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _status = '초기화 중...';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);

    final dynamic langs = await _flutterTts.getLanguages;
    final List<String> languageList = (langs as List<dynamic>)
        .map((dynamic e) => e.toString())
        .where((String e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    String? defaultLanguage;
    for (final String lang in languageList) {
      if (lang.toLowerCase().contains('ko')) {
        defaultLanguage = lang;
        break;
      }
    }
    defaultLanguage ??= languageList.isNotEmpty ? languageList.first : null;

    if (defaultLanguage != null) {
      await _flutterTts.setLanguage(defaultLanguage);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _languages = languageList;
      _selectedLanguage = defaultLanguage;
      _status = defaultLanguage == null ? '사용 가능한 언어가 없습니다.' : '언어/보이스를 선택하세요.';
    });

    await _loadVoices();
  }

  Future<void> _loadVoices() async {
    final dynamic rawVoices = await _flutterTts.getVoices;
    final List<Map<String, dynamic>> allVoices = ((rawVoices ?? <dynamic>[]) as List<dynamic>)
        .whereType<Map>()
        .map((Map e) => Map<String, dynamic>.from(e))
        .toList();

    final String? selectedLang = _selectedLanguage;
    final List<Map<String, dynamic>> filtered = selectedLang == null
        ? allVoices
        : allVoices.where((Map<String, dynamic> voice) {
            final String locale = (voice['locale'] ?? '').toString().toLowerCase();
            final String lang = selectedLang.toLowerCase();
            if (locale.isEmpty) {
              return true;
            }
            return locale == lang || locale.startsWith('${lang.split('-').first}-');
          }).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _voices = filtered;
      _selectedVoiceIndex = filtered.isNotEmpty ? 0 : null;
      _status = filtered.isEmpty
          ? '선택 언어에서 사용 가능한 보이스가 없습니다.'
          : '보이스 ${filtered.length}개를 찾았습니다.';
    });
  }

  Future<void> _applyVoice() async {
    final int? index = _selectedVoiceIndex;
    if (index == null || index < 0 || index >= _voices.length) {
      return;
    }

    final Map<String, dynamic> voice = _voices[index];
    final Map<String, String> payload = <String, String>{
      'name': (voice['name'] ?? '').toString(),
      'locale': (voice['locale'] ?? _selectedLanguage ?? '').toString(),
    };

    if (payload['name']!.isEmpty) {
      return;
    }

    await _flutterTts.setVoice(payload);
  }

  Future<void> _speak() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _status = '읽을 문장을 입력하세요.';
      });
      return;
    }

    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    if (_selectedLanguage != null) {
      await _flutterTts.setLanguage(_selectedLanguage!);
    }
    await _applyVoice();
    await _flutterTts.speak(text);

    if (!mounted) {
      return;
    }

    setState(() {
      _status = '재생 중...';
    });
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = '중지됨';
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_tts 테스트')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('상태: $_status'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '언어',
                ),
                items: _languages
                    .map(
                      (String lang) => DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) async {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedLanguage = value;
                  });
                  await _flutterTts.setLanguage(value);
                  await _loadVoices();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedVoiceIndex,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '보이스',
                ),
                items: List<DropdownMenuItem<int>>.generate(_voices.length, (int i) {
                  final Map<String, dynamic> voice = _voices[i];
                  final String name = (voice['name'] ?? 'unknown').toString();
                  final String locale = (voice['locale'] ?? '').toString();
                  final String gender = (voice['gender'] ?? '').toString();
                  final String label = [name, locale, gender]
                      .where((String e) => e.isNotEmpty)
                      .join(' / ');
                  return DropdownMenuItem<int>(
                    value: i,
                    child: Text(label.isEmpty ? 'voice-$i' : label),
                  );
                }),
                onChanged: _voices.isEmpty
                    ? null
                    : (int? value) {
                        setState(() {
                          _selectedVoiceIndex = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              Text('속도: ${_speechRate.toStringAsFixed(2)}'),
              Slider(
                value: _speechRate,
                min: 0.1,
                max: 1.0,
                onChanged: (double value) {
                  setState(() {
                    _speechRate = value;
                  });
                },
              ),
              Text('피치: ${_pitch.toStringAsFixed(2)}'),
              Slider(
                value: _pitch,
                min: 0.5,
                max: 2.0,
                onChanged: (double value) {
                  setState(() {
                    _pitch = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '읽을 문장을 입력하세요',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _speak,
                child: const Text('재생'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _stop,
                child: const Text('중지'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
