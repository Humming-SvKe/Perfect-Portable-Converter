// Minimal, robust script for handling issue/comment trigger and replying using OpenAI.
// Uses global fetch if present (Node 18+). If not present, dynamically imports node-fetch.
//
// Environment expectations:
// - OPENAI_API_KEY secret present
// - GITHUB_TOKEN available (from ${GITHUB_TOKEN})
// - GITHUB_EVENT_PATH present (GitHub Actions provides this)
const fs = require('fs');

async function getFetch() {
  if (typeof fetch === 'function') return fetch;
  try {
    const m = await import('node-fetch');
    return m.default || m;
  } catch (err) {
    throw new Error('No fetch available. On Node <18 install node-fetch OR use Node 18+ with built-in fetch.');
  }
}

async function main() {
  try {
    const eventPath = process.env.GITHUB_EVENT_PATH;
    const token = process.env.GITHUB_TOKEN;
    const openaiKey = process.env.OPENAI_API_KEY;

    if (!eventPath) throw new Error('GITHUB_EVENT_PATH not set');
    if (!openaiKey) throw new Error('OPENAI_API_KEY missing');

    const event = JSON.parse(fs.readFileSync(eventPath, 'utf8'));

    let text = '';
    if (event.comment && event.comment.body) text = event.comment.body;
    else if (event.issue && event.issue.body) text = event.issue.body;
    else {
      console.log('No comment/issue body found, exiting.');
      return;
    }

    const cmd = text.trim();
    if (!cmd.toLowerCase().startsWith('/gpt')) {
      console.log('No /gpt command found -> exit');
      return;
    }
    const prompt = cmd.replace(/^\/gpt\s*/i, '').trim();
    if (!prompt) {
      console.log('Empty prompt after /gpt -> exit');
      return;
    }

    const fetchFn = await getFetch();

    // Call OpenAI API (chat completions)
    const openaiResp = await fetchFn('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 300,
      }),
    });

    if (!openaiResp.ok) {
      const txt = await openaiResp.text();
      throw new Error(`OpenAI error: ${openaiResp.status} ${txt}`);
    }
    const openaiJson = await openaiResp.json();
    const reply = openaiJson?.choices?.[0]?.message?.content?.trim() || 'No answer from OpenAI';

    const commentsUrl = event.issue ? event.issue.comments_url : null;
    if (!commentsUrl) throw new Error('No comments_url available to post reply');

    const postRes = await fetchFn(commentsUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'User-Agent': 'github-actions-chatgpt-bot',
      },
      body: JSON.stringify({ body: reply }),
    });

    if (!postRes.ok) {
      const txt = await postRes.text();
      throw new Error(`GitHub post comment failed: ${postRes.status} ${txt}`);
    }

    console.log('Reply posted successfully.');
  } catch (err) {
    console.error('Error in handle_comment:', err);
    process.exit(1);
  }
}

main();
