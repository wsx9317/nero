import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _textToSpeech = FlutterTts();
  final TextEditingController _ttsController = TextEditingController(
    text: '안녕하세요. TTS 단독 테스트 문장입니다.',
  );

  bool _speechReady = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _status = '초기화 전';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isListening = status == 'listening';
          _status = 'STT 상태: $status';
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _status = 'STT 오류: ${error.errorMsg}';
          _isListening = false;
        });
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _speechReady = available;
      _status = available ? 'STT 준비 완료' : 'STT 사용 불가(권한/기기 확인)';
    });
  }

  void _initTts() {
    _textToSpeech.setLanguage('ko-KR');
    _textToSpeech.setSpeechRate(0.5);
    _textToSpeech.setPitch(1.0);
  }

  Future<void> _startListening() async {
    if (!_speechReady) {
      setState(() {
        _status = 'STT가 준비되지 않았습니다.';
      });
      return;
    }

    await _speechToText.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        if (!mounted) {
          return;
        }
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = true;
      _status = '듣는 중...';
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      _status = '듣기 중지';
    });
  }

  Future<void> _speakTestText() async {
    final text = _ttsController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _status = 'TTS 입력 문장을 먼저 작성해주세요.';
      });
      return;
    }

    await _textToSpeech.speak(text);
    if (!mounted) {
      return;
    }
    setState(() {
      _status = 'TTS 테스트 재생';
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    _textToSpeech.stop();
    _ttsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STT / TTS 테스트'),
      ),
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
            children: [
              Text('상태: $_status'),
              const SizedBox(height: 12),
              Text('듣는 중: ${_isListening ? '예' : '아니오'}'),
              const SizedBox(height: 20),
              const Text(
                'TTS 단독 테스트',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ttsController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '읽을 문장을 입력하세요',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _speakTestText,
                child: const Text('TTS 재생'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/tts/flutter'),
                child: const Text('flutter_tts 전용 페이지 열기'),
              ),
              const Divider(height: 28),
              const Text(
                'STT 단독 테스트',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isListening ? null : _startListening,
                child: const Text('STT 시작'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isListening ? _stopListening : null,
                child: const Text('STT 중지'),
              ),
              const SizedBox(height: 20),
              const Text('인식 결과'),
              const SizedBox(height: 8),
              Text(
                _recognizedText.isEmpty ? '아직 인식된 텍스트가 없습니다.' : _recognizedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}