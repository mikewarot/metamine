math.randomseed(sas.now())
port = math.random(10101, 20202)
srv = server(port)
clis = srv.clients


print('PORT '..port)

-- example 1
cli1 = client('127.0.0.1:'..port)
cli1.output = enchant('GET /index.html HTTP/1.1\r\nHost: localhost\r\n\r\n')

-- parse headers
header = split(clis.input, '\r\n\r\n')
lines2 = split(header, '\r\n')
intro = lines2[1]
mpv = split(intro, ' ')
method = mpv[1]
path = mpv[2]
version = mpv[3]

-- page
wwwpath = prepend1(path, 'www')
content = infile(wwwpath)

-- responses
header1 = 'HTTP/1.1 200 OK\r\nContent-Length: '
len = totext(length(content))
header2 = prepend1(len, header1)
header = append1(header2, '\r\n\r\n')

response = append(header, content)
stream = concat(response)

clis.output = stream
