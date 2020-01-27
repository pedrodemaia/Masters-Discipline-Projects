function [h,q,W,T,A,c,b,sigmah,sigmaq] = expTerm
    % dimensões do problema
    n = 10;
    K = 3;
    
    % índice das variáveis do período 1 (exatas)
    idx1 = 1;
    idy11 = n+1;
    idy12 = 2*n+1;
    idy13 = 3*n+1;
    slack = 4*n+1;
    
    % índice das variáveis do período 2 (estocásticas)
    idx2 = 1;
    idy21 = n+1;
    idy22 = 2*n+1;
    idy23 = 3*n+1;
    slack = 4*n+1;
    
    % parâmetros
    meta = 17;
    
    CI = [4 3.8 5 6 4 1 3 3 1 1];
    
    LC = [4 6 1 5 2 5.5 6 4 4 4;
          0.5 0.5 0.5 0.5 2 2 4 4 4 4];
      
    ce = [14 9.8 18.2 8.4 21 22.4 22.4 22.4 22.4 22.4];
    sigmace = [6 4.5 0.3 6 6 6 6 6 6 6];
    
    co = [4.8 5.4 3.84 6.6 4.8 4.56 4.68 4.8 4.56 4.56];
    sigmaco = [1.2 2.1 0.3 1.5 1.2 1.5 2.7 1.8 1.2 0.6];
    
    d = [13 10 6.5; 12 11 7];
    sigmad = [6 5 3.2];
    
    % função objetivo
    c = [ce repmat(co,1,K)];
    
    q = [1.5*ce repmat(co,1,K)];
    sigmaq = [sigmace repmat(sigmaco,1,K)];
    
    %% restrições lineares
    A = zeros(2*n, 4*n);
    b = zeros(2*n,1);
    Aeq = zeros(K, 4*n);
    beq = zeros(K,1);
    
    % limite de crescimento
    A(1:n,1:n) = eye(n);
    b(1:n) = LC(1,:)';
    
    % capacidade de produção
    A(n+1:2*n,n+1:end) = repmat(eye(n),1,K);
    b(n+1:2*n) = CI';
    
    % atendimento de demanda
    temp = repmat({ones(1,n)},K,1);
    Aeq(:,n+1:end) = blkdiag(temp{:});
    beq = d(1,:)';
    
    %% restrições estocásticas
    T = zeros(2*n, 4*n);
    W = zeros(2*n, 4*n);
    h = zeros(2*n,1);
    sigmah = zeros(2*n,1);
    Teq = zeros(K+1, 4*n);
    Weq = zeros(K+1, 4*n);
    heq = zeros(K+1,1);
    sigmaheq = zeros(K+1,1);
    
    % limite de crescimento
    W(1:n,1:n) = eye(n);
    h(1:n) = LC(2,:)';
    
    % capacidade de produção
    W(n+1:2*n,n+1:end) = repmat(eye(n),1,K);
    T(n+1:2*n,1:n) = -eye(n);
    h(n+1:2*n) = CI';
    
    % atendimento de demanda
    temp = repmat({ones(1,n)},K,1);
    Weq(1:K,n+1:end) = blkdiag(temp{:});
    heq(1:K) = d(2,:)';
    sigmaheq(1:K) = sigmad';
    
    % meta de crescimento
    Weq(K+1,1:n) = 1;
    Teq(K+1,1:n) = 1;
    heq(K+1) = meta;
    
    %% adição de slacks
    a1 = size(A,1);
    t1 = size(T,1);
    
    % função objetivo
    c = [c zeros(1,a1)]';
    q = [q zeros(1,t1)]';
    sigmaq = [sigmaq zeros(1,t1)]';
    
    % restrições lineares
    A = [A eye(a1);
         Aeq zeros(size(Aeq,1),a1)];
    b = [b; beq];
    
    % restrições estocásticas
    T = [T zeros(t1,a1);
         Teq zeros(size(Teq,1),a1)];
    W = [W eye(t1);
         Weq zeros(size(Weq,1),t1)];
    h = [h; heq];
    sigmah = [sigmah; sigmaheq];    
end

