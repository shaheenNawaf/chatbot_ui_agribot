export default async function handler(req, res) {
  let body;
  try {
    body = await new Promise((resolve, reject) => {
      let data = '';
      req.on('data', chunk => data += chunk);
      req.on('end', () => resolve(JSON.parse(data)));
      req.on('error', reject);
    });
  } catch (e) {
    return res.status(400).json({ error: 'Invalid request body' });
  }

  const response = await fetch("http://165.22.247.173:8000/chat", {
    method: 'POST',
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const data = await response.json();
  res.status(response.status).json(data);
}