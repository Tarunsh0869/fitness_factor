import { useEffect, useState } from 'react';

export const useWebSocket = (url: string) => {
  const [data, setData] = useState(null);

  useEffect(() => {
    const socket = new WebSocket(url);

    socket.onmessage = (event) => {
      try {
        setData(JSON.parse(event.data));
      } catch (error) {
        console.error('Failed to parse WebSocket message', error);
      }
    };

    return () => {
      if (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING) {
        socket.close();
      }
    };
  }, [url]);

  return data;
};