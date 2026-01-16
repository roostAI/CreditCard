function fn() {
  const envVars = {};
  // Get all environment variables from the OS
  const System = Java.type('java.lang.System');
  const env = System.getenv();
  // karate.log('env is:', env);
  const keys = env.keySet().toArray();
  for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      envVars[key] = env.get(key);
      if (key === 'API_HOST' || key === 'URL_BASE') {
        karate.log('set envVars for key:', key, ' with ', env.get(key));
      }
  }
  // Add Karate's own env variable
  envVars['karate.env'] = karate.env;
  const config = {
      karate: {
          properties: {...envVars,
          //additionalProperty: 'value'
          },
      }
  };
  // karate.log('Karate configuration:', config);
  return config;
}