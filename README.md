# At This Moment
iOS 기기를 이용해 언제 어디서나 설치된 CCTV 영상을 확인할 수 있습니다.

WebRTC 적용으로 실시간에 가까운 영상, 음성 통화가 가능합니다.


<a href='https://apps.apple.com/kr/app/%EC%A7%80%EA%B8%88-%EC%9D%B4-%EC%88%9C%EA%B0%84/id6497109910'>🎁App Store</a>

## 사용된 기술

- **Swift (** **UIKit, Combine, MVVM )**
- **Firebase** ( RealtimeDatabase, Storage, Authentication )
- **WebRTC** ( https://github.com/stasel/WebRTC )
- **Starscream** ( https://github.com/daltoniam/Starscream )
- **Python** ( Flask, Apple REST API )
- **Node.js** ( SignalingServer )

## **주요기능**
### Account
Apple, Google 로그인, 로그아웃을 지원하며, Apple REST API를 사용해 회원탈퇴 기능을 구현하였습니다.
|Sign In Apple|Sign In Google| Apple REST | Google REST |
|------|------|------|------|
|![SignInApple1 5](https://github.com/Seok231/iOS_CCTV/assets/97385742/043198ad-4660-402d-a282-b0f155c8768d)|![SignInGoogle](https://github.com/Seok231/iOS_CCTV/assets/97385742/2b5bc504-3d2b-419b-ac4f-cb9315b4d721)|![DeleteApple1 5](https://github.com/Seok231/iOS_CCTV/assets/97385742/48054b5c-e48f-4ad5-a778-c76027d3d1ee)|![DeleteGoogle1 5](https://github.com/Seok231/iOS_CCTV/assets/97385742/24a2a54b-0cb5-4bd3-802e-4e893fd4383f)
<br/>

### WebRTC

기존 SRT가 아닌 WebRTC를 적용해 보다 안정적이고 양방향으로 음성과 영상을 전달할 수 있습니다.

|낮은 지연시간|토치, 카메라 포지션 원격 변경|
|---|---|
|![실시간 영상 테스트](https://github.com/Seok231/iOS_CCTV/assets/97385742/344c7c66-f145-4c71-9096-1c986cd33013)|![토치, 카메라 전환](https://github.com/Seok231/iOS_CCTV/assets/97385742/f58d003e-a452-4b33-9917-591ae3028ce1)
<br/>
Signaling Sever에서 HTTPHeader로 Host, Client를 구분하여, Host가 연결이 끊길 시 오프라인 처리 되도록 설정되어 있습니다. <br/>
HTTPHeader로 Room 개념으로 분리해 Host가 보내는 신호를 분리, 다중 사용자들이 사용할 수 있도록 구현하였습니다.
<br/>
<br/>

|온라인 오프라인 처리|다중연결|
|---|---|
|![온라인 오프라인](https://github.com/Seok231/iOS_CCTV/assets/97385742/af3dcf1c-bbc0-404c-ad4a-b0c887a81c75)|![다중연결](https://github.com/Seok231/iOS_CCTV/assets/97385742/179bd8fa-01fc-4b14-9fb2-c5605afef941)

