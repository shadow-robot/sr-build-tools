FROM prima/filebeat:latest

COPY ./filebeat.yml /filebeat.yml
# this is a dummy certificate - the elk stack is configured to accept
# any traffic so should not be used on an opened server
COPY ./logstash-beats.crt /logstash-beats.crt
