import { useState, useEffect } from 'react';

export const useEventStream = (url: string) => {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    const eventSource = new EventSource(url);

    eventSource.onmessage = (event) => {
      try {
        const parsedData = JSON.parse(event.data);
        setData(parsedData);
      } catch (err) {
        console.error('Failed to parse event data:', err);
      }
    };

    eventSource.onerror = (error) => {
      console.error('EventSource connection failed:', error);
      eventSource.close();
    };

    return () => {
      eventSource.close();
    };
  }, [url]);

  return data;
};