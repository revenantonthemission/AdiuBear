const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const GEMINI_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_KEY) {
  console.error("❌ 환경변수 GEMINI_API_KEY가 설정되지 않았습니다.");
  process.exit(1);
}

app.post('/gemini', async (req, res) => {
  const { prompt, base64Image } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: "prompt 필드가 필요합니다." });
  }

  const endpoint = base64Image
    ? `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_KEY}`
    : `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_KEY}`;

  const parts = [{ text: prompt }];
  if (base64Image) {
    parts.push({
      inlineData: {
        mimeType: "image/jpeg",
        data: base64Image,
      },
    });
  }

  try {
    const response = await axios.post(endpoint, {
      contents: [{ parts }],
    });

    const text = response.data.candidates?.[0]?.content?.parts?.[0]?.text ?? "응답 없음";

    res.json({ result: text });
  } catch (err) {
    console.error(err?.response?.data || err.message);
    res.status(500).json({ error: "Gemini API 호출 실패" });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🚀 Gemini API 중계 서버 실행 중: http://localhost:${PORT}`);
});