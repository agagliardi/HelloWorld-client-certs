REM  ------------------------------------------------------------------------------------
REM  Copyright (c) Red Hat, Inc.
REM  All rights reserved. 
REM  
REM  Licensed under the Apache License, Version 2.0 (the ""License""); you may not use this 
REM  file except in compliance with the License. You may obtain a copy of the License at 
REM  http://www.apache.org/licenses/LICENSE-2.0  
REM  
REM  THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
REM  EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTIES OR 
REM  CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABLITY OR 
REM  NON-INFRINGEMENT. 
REM 
REM  See the Apache Version 2.0 License for specific language governing permissions and 
REM  limitations under the License.
REM  ------------------------------------------------------------------------------------
REM
REM file: gen-win-ssl-certs.bat
REM date: 2015-07-01
REM what: Procedure to create client auth certificate set for an ActiveMQ broker
REM       and a .NET client. "keytool" is supplied by jdk.
REM
REM These files are created:
REM broker-jks.keystore   BROKER_KEYSTORE
REM                         ActiveMQ broker conf\activemq.xml broker sslContext.
REM broker-jks.truststore BROKER_TRUSTSTORE
REM                         ActiveMQ broker conf\activemq.xml broker sslContext.
REM ca.crt                CA_CERT
REM                         installed in client machine Trusted Root Certificate Authorities store
REM client.p12            CLIENT_PRIVATE_KEYS
REM                         installed in client machine Personal Certificates store.
REM client.crt            CLIENT_CERT
REM                         referred to/loaded by the C# example Hello World application code.
REM
REM * The BROKER_KEYSTORE and BROKER_TRUSTSTORE do not need to be installed. The ActiveMQ
REM   broker refers to these files in conf\activemq.xml.
REM * CA_CERT and CLIENT_PRIVATE_KEYS are installed in the certificates stores of the client system.
REM * CLIENT_CERT is used in creating an X509CertificateCollection. It is the certfile in:
REM     ClientCertificates.Add(X509Certificate.CreateFromCertFile(certfile))
REM
REM The password for every store and certificate is "password".

REM All certificates are created in this subfolder
SET CERT_LOC=%CD%\win-ssl-certs

REM Define the CN of the self-signed certificate authority.
REM This value identifies the CA in the windows cert store.
SET CA_CN=reallly-trust-me.org

REM Define the CN of the broker for the broker's cert. Typically this is the 'hostname' of the machine
REM on which the activemq broker is running.
SET BROKER_CN=somehost.example.com

REM Define the CN of the client. A client presenting this certificate will be authenticated
REM as this user name in the ActiveMQ broker. Note that the client must still present
REM the correct username and password in the connection Address.
SET CLIENT_CN=client

REM Define file names
SET          CA_KEYSTORE=ca-jks.keystore
SET      BROKER_KEYSTORE=broker-jks.keystore
SET      CLIENT_KEYSTORE=client-jks-keystore
SET    BROKER_TRUSTSTORE=broker-jks.truststore
SET              CA_CERT=ca.crt
SET BROKER_CERT_SIGN_REQ=broker.csr
SET          BROKER_CERT=broker.crt
SET CLIENT_CERT_SIGN_REQ=client.csr
SET          CLIENT_CERT=client.crt
SET  CLIENT_PRIVATE_KEYS=client.p12

REM Define some repeated patterns identifying the various stores
SET     CA_STORE=-storetype jks -keystore     %CA_KEYSTORE% -storepass password
SET BROKER_STORE=-storetype jks -keystore %BROKER_KEYSTORE% -storepass password
SET CLIENT_STORE=-storetype jks -keystore %CLIENT_KEYSTORE% -storepass password
SET KEY_PASSWORD=-keypass password

REM Recreate entire cert folder
rmdir /s /q %CERT_LOC%
mkdir       %CERT_LOC%
pushd       %CERT_LOC%

REM Create a key and self-signed certificate, the CA certificate authority, to sign certificate requests
REM ----------------------------------------------------------------------------------------------------
keytool %CA_STORE% %KEY_PASSWORD% -alias ca -genkey  -keyalg RSA -sigalg SHA256withRSA -dname "O=Reallly Trust Me Inc.,CN=%CA_CN%" -validity 9999 -ext bc:c=ca:true
keytool %CA_STORE%                -alias ca -exportcert -rfc > %CA_CERT%

REM Create a key pair for the broker, and sign it with the CA
REM ---------------------------------------------------------
keytool %BROKER_STORE% %KEY_PASSWORD% -alias broker -genkey -keyalg RSA -sigalg SHA256withRSA -keysize 2048 -dname "O=Broker,CN=%BROKER_CN%" -validity 9999 -ext bc=ca:false -ext eku=serverAuth

keytool %BROKER_STORE% -alias broker -certreq    -file %BROKER_CERT_SIGN_REQ%
keytool %CA_STORE%     -alias ca -gencert -rfc -infile %BROKER_CERT_SIGN_REQ% -outfile %BROKER_CERT% -ext bc=ca:false -ext eku=serverAuth

REM Import CA and broker certificates into broker keystore:
REM -------------------------------------------------------
keytool %BROKER_STORE% %KEY_PASSWORD% -importcert -alias ca     -file     %CA_CERT% -noprompt
keytool %BROKER_STORE% %KEY_PASSWORD% -importcert -alias broker -file %BROKER_CERT%

REM Create a key pair for the client. Create sign request and sign it with the CA creating client cert file:
REM --------------------------------------------------------------------------------------------------------
keytool %CLIENT_STORE% %KEY_PASSWORD% -alias client -genkey -keyalg RSA -sigalg SHA256withRSA -keysize 2048 -dname "O=Client,CN=%CLIENT_CN%" -validity 9999 -ext bc=ca:false -ext eku=clientAuth

keytool %CLIENT_STORE% -alias client -certreq    -file %CLIENT_CERT_SIGN_REQ%
keytool %CA_STORE%     -alias ca -gencert -rfc -infile %CLIENT_CERT_SIGN_REQ% -outfile %CLIENT_CERT% -ext bc=ca:false -ext eku=clientAuth

REM Import CA and client certs into client keystore:
REM ------------------------------------------------
keytool %CLIENT_STORE% %KEY_PASSWORD% -importcert -alias ca     -file     %CA_CERT% -noprompt
keytool %CLIENT_STORE% %KEY_PASSWORD% -importcert -alias client -file %CLIENT_CERT% -noprompt

REM Export client private key and chain of trust certs to Personal Information Exchange (.p12):
REM -------------------------------------------------------------------------------------------
keytool -v -importkeystore -srckeystore %CLIENT_KEYSTORE% -srcstorepass password -srcalias client -destkeystore %CLIENT_PRIVATE_KEYS% -deststorepass password -destkeypass password -deststoretype PKCS12 -destalias client

REM Create a trust store for the broker, import the CA cert:
REM --------------------------------------------------------
keytool -storetype jks -keystore %BROKER_TRUSTSTORE% -storepass password %KEY_PASSWORD% -importcert -alias     ca -file     %CA_CERT% -noprompt

REM Make client cert legible in .NET
REM --------------------------------
dos2unix %CLIENT_CERT%

REM Clean up
del %CA_KEYSTORE%
del %BROKER_CERT_SIGN_REQ%
del %BROKER_CERT%
del %CLIENT_CERT_SIGN_REQ%
del %CLIENT_STORE%

popd
