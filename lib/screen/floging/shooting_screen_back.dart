import 'package:camera/camera.dart';
import 'package:flog/screen/floging/shooting_screen_front.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

class ShootingScreen extends StatefulWidget {
  final String? backImagePath;
  const ShootingScreen({Key? key, this.backImagePath}) : super(key: key);

  @override
  State<ShootingScreen> createState() => _ShootingScreenState();
}

class _ShootingScreenState extends State<ShootingScreen> {
  CameraController? _cameraController; //카메라 컨트롤러
  String? _tempBackImagePath; //임시 후면 사진 저장

  bool _isCameraReady = false;
  bool _isCameraInitialized = false; //카메라 초기화되었는지
  bool _isProcessing = false; //사진 찍히고 있는지
  bool _isFlashOn = true; //플래시 켜져있는지

  //카메라 초기화
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  //후면 카메라 - 가능한 카메라들 목록을 하나하나 검사하면서 후면 카메라를 발견하면 탐색 멈춤
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    for(CameraDescription camera in cameras) {
      if(camera.lensDirection == CameraLensDirection.back) {
        _initializeCameraController(camera);
        break;
      }
    }
    setState(() {
      _isCameraInitialized = true; // 카메라 초기화 완료
    });
  }

  //카메라 컨트롤러 initalize
  void _initializeCameraController(CameraDescription camera) {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    _cameraController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isCameraReady = true; //카메라 컨트롤러 initalize 마쳤을 때
        });
      }
    });
  }

  //전면 카메라 화면으로 전환하는 함수
  void _navigateToFrontScreen(BuildContext context) {
    if (_tempBackImagePath != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShootingScreenFront(
            backImagePath: _tempBackImagePath!,
          ),
        ),
      );
    }
  }

  //후면 카메라 촬영
  Future<void> _takeBackPicture(context) async {
    if (_cameraController == null || !_isCameraReady || _isProcessing) return;
    setState(() {
      _isProcessing = true; // 사진 처리 중 표시
    });

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _tempBackImagePath = image.path;
        _isProcessing = false; // 사진 처리 완료
      });
      _navigateToFrontScreen(context);
    } catch (e) {
      setState(() {
        _isProcessing = false; // 사진 처리 실패 시 처리 중 표시 해제
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope( //뒤로가기 막음
      onWillPop: () async => false,
      child : Expanded(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'Floging',
              style: GoogleFonts.balooBhaijaan2(
                textStyle: const TextStyle(
                  fontSize: 30,
                  color: Color(0xFF62BC1B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            elevation: 0.0, //그림자 없음
            centerTitle: true,
          ),
          /*---화면---*/
          backgroundColor: Colors.white, //화면 배경색
          body: Center(
            child : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height:10), //간격
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20), //둥근 모서리
                        child: SizedBox(
                          width: 360,
                          height: 540,
                          child: _cameraController != null && _isCameraReady
                              ? CameraPreview(_cameraController!)
                              : Container(color: Colors.white,),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 20,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: 30,
                            height: 30,
                            child: Image.asset(
                              "button/close.png",
                              width: 20,
                              height: 20,
                              color: Colors.white,
                            ),
                          )
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: InkWell( //플래시 아이콘 버튼
                          onTap: () {
                            setState(() {
                              _isFlashOn = !_isFlashOn; // 플래시 상태를 토글
                              if (_isFlashOn) {
                                _cameraController?.setFlashMode(FlashMode.auto);
                              } else {
                                _cameraController?.setFlashMode(FlashMode.off);
                              }
                            });
                          },
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8)
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  "button/flash.png",
                                  width: 50,
                                  height: 50,
                                  color: _isFlashOn ? Colors.white : Colors.grey, // 플래시 상태에 따라 아이콘 색상 변경
                                ),
                                Text(
                                  _isFlashOn ? "자동" : "OFF", // 텍스트 내용
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _isFlashOn ? Colors.white : Colors.grey, // 텍스트 색상 변경
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height:10), //간격
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell( //후면 카메라 촬영 버튼
                        onTap:
                        _cameraController != null && _isCameraReady ? () {
                          _takeBackPicture(context);
                        }
                        : null,
                        child: _isProcessing ? Center( //로딩바 구현 부분
                          child: Column(
                            children: [
                              SpinKitPumpingHeart(
                                  color: Colors.green.withOpacity(0.2),
                                  size: 50.0, //크기 설정
                                  duration: const Duration(seconds: 2),
                                ),
                              const Text(
                                '촬영중!',
                                style: TextStyle(
                                color: Color(0xFF609966),
                                fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          ) : Image.asset(
                          "button/shooting.png",
                          width: 70,
                          height: 70,
                          color: _cameraController != null && _isCameraReady && _isCameraInitialized
                              ? const Color(0xFF62BC1B)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}
