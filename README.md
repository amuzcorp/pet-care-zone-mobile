# Pet Care Zone

반려동물 돌봄을 위한 맞춤형 모바일 펫케어 서비스

## Mobile Develop Environment
- Android Studio : Jellyfish | 2023.3.1 Patch 2
- Flutter version : 3.7.3
- Java : openjdk version "17.0.11" 2024-04-16 LTS
- Kotlin : 1.9.0
  - Gradle
      - compileSDK : 34
      - minSdk : 28
      - targetSdk : 34
      - jvmTarget : 1.8
- ConnectSDK : 1.6.2

## Web Develop Environment
- Node : 21.6.0
- React
  - Server API Broker : [MQTT](https://www.emqx.com/en/blog/how-to-use-mqtt-in-react)
  - 실시간 스트리밍 홈 캠 : [WebRTC](https://webrtc.org/?hl=ko) , [WebRTC Github](https://github.com/webrtc)
  - 캠 녹화 : [RecordRTC](https://recordrtc.org/)
  - Peer 연결 broker : https://github.com/coturn/coturn
  - 전역상태: recoil
