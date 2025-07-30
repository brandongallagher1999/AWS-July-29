const http = require('http');

const options = {
  hostname: 'localhost',
  port: process.env.PORT || 3000,
  path: '/health',
  method: 'GET',
  timeout: 5000
};

const req = http.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const healthData = JSON.parse(data);
      
      if (res.statusCode === 200 && healthData.status === 'healthy') {
        console.log('✅ Health check passed');
        process.exit(0);
      } else {
        console.error('❌ Health check failed:', healthData);
        process.exit(1);
      }
    } catch (error) {
      console.error('❌ Failed to parse health check response:', error);
      process.exit(1);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Health check request failed:', error.message);
  process.exit(1);
});

req.on('timeout', () => {
  console.error('❌ Health check timed out');
  req.destroy();
  process.exit(1);
});

req.end(); 