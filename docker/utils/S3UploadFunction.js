const AWS = require("aws-sdk"); const uuid = require("uuid");
const sts = new AWS.STS(); const roleToAssume = process.env.role; const bucket = process.env.bucket;
const apigateway = new AWS.APIGateway();

exports.handler = (event, context, callback) => {
  let apiKeyId = event.requestContext.identity.apiKeyId;
  let customername = "unknown customer"
  
  var params = {
    apiKey: apiKeyId,
    includeValue: true
  };
  apigateway.getApiKey(params, function(err, data) {
    if (err) customername="error getting customer" // an error occurred
    else     customername=data.name;           // successful response
  });

  let sessionName = uuid.v4();
    sts.assumeRole({
      RoleArn: roleToAssume,
      RoleSessionName: `${apiKeyId}_${sessionName}`,
      ExternalId: apiKeyId
    }).promise().then(assumed => {
      let result=`ACCESS_KEY_ID=${assumed.Credentials.AccessKeyId}\n`;
      result+=`SECRET_ACCESS_KEY=${assumed.Credentials.SecretAccessKey}\n`;
      result+=`SESSION_TOKEN=${assumed.Credentials.SessionToken}\n`;
      result+=`EXPIRATION=${new Date(assumed.Credentials.Expiration).getTime()}\n`;
      result+=`URL=s3://${bucket}/${assumed.AssumedRoleUser.AssumedRoleId}/\n`;
      result+=`CUSTOMER_NAME=${customername}\n`;
      callback(null, {
        statusCode: 200,
        body: result
      });
    }).catch(err=>{
      console.log('ERROR:',err);
      callback(err);
    });

};
