const fs = require('fs');
const https = require('https');
const dgram = require('dgram');

const HTTPS_PORT = process.env.HTTPS_PORT ?? 443;
const NTP_PORT = process.env.NTP_PORT ?? 123;
const MTLS = process.env.MTLS.toLowerCase() === "true";

/** Create HTTPS listener **/
https
  .createServer(
    {
      requestCert: MTLS,
      rejectUnauthorized: MTLS,
      ca: fs.readFileSync('ca/ca.crt'),
      cert: fs.readFileSync('certs/server.crt'),
      key: fs.readFileSync('certs/server.key')
    },
    (req, res) => {
      res.writeHead(200);
      res.end(`Connection success to ${process.env.SERVER_NAME}`);
    }
  )
  .listen(HTTPS_PORT, "0.0.0.0");
console.log(`Listening on ${HTTPS_PORT}/tcp ${MTLS ? 'with' : 'without'} mTLS`)

/** Create NTP listener **/
if (NTP_PORT > 0) {
  const socket = dgram.createSocket('udp4');

  socket.on('message', function(msg, rinfo) {
    console.log(rinfo);
    socket.send(Buffer.from(`${process.env.SERVER_NAME} received ${Buffer.byteLength(msg)} bytes from ${rinfo.address}\n`), rinfo.port, rinfo.address);
  });

  socket.on('listening', () => {
    console.log(`Listening on ${socket.address().port}/udp`);
  });

  socket.bind(NTP_PORT);
}
