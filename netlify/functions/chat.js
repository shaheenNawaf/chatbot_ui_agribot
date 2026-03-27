exports.handler = async (event) => {
  const response = await fetch("http://165.22.247.173:8000/chat", {
    method: 'POST',
    headers: { "Content-Type": "application/json" },
    body: event.body,
  });

  const data = await response.json();
  return {
    statusCode: response.status,
    body: JSON.stringify(data),
  };
};