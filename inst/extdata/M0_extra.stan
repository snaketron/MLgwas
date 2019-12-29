data {
  int N; // number of all entries
  int Nt; // number of traits
  int Ns; // number of all SNPs
  // int <lower=0, upper=1> T [Nt]; // 0 = continuous, 1 = dichotomous
  matrix [N, Ns] X; // index of all individuals
  matrix [N, Nt] Y;

  //scale for the half -t prior for tau// (tau0 = scale_global *sigma)
  real <lower=0> scale_global;

  //degrees of freedom for the half-t prior for tau
  real <lower=1> nu_global;

  //degrees of freedom for the half-t priors for lambdas (1 = HS)
  real <lower=1> nu_local;
}

parameters {
  vector [Nt] alpha_trait;
  vector <lower = 0> [Nt] sigma;
  vector [Ns] z [Nt];
  vector <lower=0> [Nt] r1_global;
  vector <lower=0> [Nt] r2_global;
  vector <lower =0> [Ns] r1_local [Nt];
  vector <lower =0> [Ns] r2_local [Nt];
}



transformed parameters {
  vector [Ns] beta_snp [Nt];
  vector <lower=0> [Nt] tau; //global shrinkage parameter
  vector <lower=0> [Ns] lambda [Nt]; //local shrinkage parameters

  for(t in 1:Nt) {
    lambda[t] = r1_local[t] .* sqrt(r2_local[t]);
    tau[t] = r1_global[t] * sqrt(r2_global[t]);
    beta_snp[t] = z[t] .* lambda[t]*tau[t];
  }
}


model {
  for(t in 1:Nt) {
    Y[,t] ~ normal(alpha_trait[t] + X * beta_snp[t], sigma[t]);
    // Y[,d] ~ bernoulli_logit(alpha_trait[d+Ntq] + X[i] .* beta_snp[d+Ntq]);
  }
  sigma ~ cauchy(0, 1);
  alpha_trait ~ normal(0, 20);

  for(t in 1:Nt) {
    z[t] ~ std_normal();
    r1_local[t] ~ normal(0.0, 1.0);
    r1_global[t] ~ normal (0.0, scale_global*sigma);
    r2_local[t] ~ inv_gamma(0.5*nu_local, 0.5*nu_local);
    r2_global[t] ~ inv_gamma (0.5*nu_global , 0.5*nu_global);
  }
}
