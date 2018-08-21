const AWS = require("aws-sdk"); const uuid = require("uuid");
const sts = new AWS.STS(); const roleToAssume = process.env.role; const bucket = process.env.bucket;
exports.handler = (event, context, callback) => {
  // console.log('event:', event);
  // console.log('context:', context);
  let apiKeyId = event.requestContext.identity.apiKeyId;
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
      callback(null, {
        statusCode: 200,
        body: result
      });
    }).catch(err=>{
      console.log('ERROR:',err);
      callback(err);
    });

};
