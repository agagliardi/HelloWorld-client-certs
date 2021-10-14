# HelloWorld-client-certs
HelloWorld-client-certs  an AMQ Client .Net Core (AMQP.Net Lite) example that uses certificates

Requirements:
 - .Net Core 3.1
 - AMQ 7 (Artemis) 
 - Java for AMQ in the path
 - Windows 2016

Download the AMQ Client .Net Core from the Red Hat Download website
Install the NuGet package locally
Build the project
~~~
dotnet build .
~~~
Create all required certificates with the `gen-win-ssl-certs.bat`.
**NOTE** Windows 2016 requires sha256 certificates

Install the <PROJECT FOLDER>/win-ssl-certs/ca.crt in "Trusted Root Certification Authorities"
Install the <PROJECT FOLDER>/win-ssl-certs/client.crt in "Personal"
Download and install AMQ 7 (Artemis) locally 
Set up a new broker's acceptor including the generated key/trust store
~~~
         <acceptor name="artemisSSL">tcp://0.0.0.0:61617?sslEnabled=true;keyStorePath=<PROJECT FOLDER>/win-ssl-certs/broker-jks.keystore;keyStorePassword=password;broker.trustStorePath=<PROJECT FOLDER>/win-ssl-certs/broker-jks.truststore;trustStorePassword=password</acceptor>
~~~

Run the project
~~~
dotnet run
~~~

## Troubleshooting
Enable SChannel logging: https://docs.microsoft.com/en-us/troubleshoot/iis/enable-schannel-event-logging
Enable AMQ/Artemis Java network tracing with `DEBUG_ARGS=-Djavax.net.debug=all` on top of `artemis.profile`
