const functions = require("firebase-functions");
var admin = require("firebase-admin");
const axios = require("axios");

var serviceAccount = require("./flog-e708e-firebase-adminsdk-aj67m-97a960b137.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

// 랜덤한 시간 생성 함수
function getRandomTime() {
  const hours = Math.floor(Math.random() * 24);
  const minutes = Math.floor(Math.random() * 60);
  const cronExpression = `${minutes} ${hours} * * *`; // 매일 랜덤한 시간

  return cronExpression;
}

// 알림 전송 함수
async function groupNotification(groupNo, title, body) {
  const headers = {
    "Content-Type": "application/json",
    "Authorization":
    "key=AAAAT-_37n8:APA91bG1SGAS3DipkjSH4C3pFveprmKolT4xC8LKR8Lk7w7ghcMdOZMzVSVCqCjcF847-x3aYHV4YDLZaIzXTOE7cvRssSG9lIJwE9IVqYJZi34MkHkMR9LYYAXmC5hI3r3hMzzo2dyU",
  };

  const requestBody = {
    to: `/topics/${groupNo}`,
    notification: {title, body},
    data: {KEY: "VALUE"},
  };

  try {
    const response = await axios.post(
        "https://fcm.googleapis.com/fcm/send",
      JSON.stringify(requestBody),
      {headers},
    );

    if (response.status === 200) {
      console.log(response.data);
    } else {
      console.error(response.statusText);
    }
  } catch (error) {
    console.error(error.message);
  }
}

// 매일 랜덤한 시간에 알림 보내기
exports.scheduleNotifications = functions.pubsub
  .schedule(getRandomTime())
  .timeZone("Asia/Seoul")
  .onRun(async (context) => {
    // 매일 랜덤한 시간에 실행되는 로직
    const groupNo = "0"; // 알림을 보낼 그룹 번호
    const title = "❗FLOG TIME입니다❗";
    const body = "가족들은 지금 무엇을 하고 있을까요? 지금 당장 상태를 알리고 확인하세요!";

    // 알림 전송 함수 호출
    await groupNotification(groupNo, title, body);
    console.log("Function triggered with changes!");
    return null;
  });
