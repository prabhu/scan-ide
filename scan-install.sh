#! /usr/bin/env bash

GOSEC_VERSION=2.2.0
TFSEC_VERSION=0.19.0
KUBESEC_VERSION=2.3.1
KUBE_SCORE_VERSION=1.5.1
DETEKT_VERSION=1.6.0
GITLEAKS_VERSION=4.1.0
SC_VERSION=2020.1.3
PMD_VERSION=6.22.0
JQ_VERSION=1.6
FSB_VERSION=1.10.1
FB_CONTRIB_VERSION=7.4.7
SB_VERSION=4.0.1
PMD_VERSION=6.22.0
PMD_JAVA_OPTS=""
SPOTBUGS_HOME=/opt/spotbugs
SHIFTLEFT_HOME=/opt/sl-cli
export PATH=${PATH}:/opt/sl-cli:/usr/local/bin:

mkdir -p /usr/local/bin \
    && curl -LO "https://github.com/securego/gosec/releases/download/v${GOSEC_VERSION}/gosec_${GOSEC_VERSION}_linux_amd64.tar.gz" \
    && tar -C /usr/local/bin/ -xvf gosec_${GOSEC_VERSION}_linux_amd64.tar.gz \
    && chmod +x /usr/local/bin/gosec \
    && rm gosec_${GOSEC_VERSION}_linux_amd64.tar.gz \
    && curl -LO "https://storage.googleapis.com/shellcheck/shellcheck-stable.linux.x86_64.tar.xz" \
    && tar -C /tmp/ -xvf shellcheck-stable.linux.x86_64.tar.xz \
    && cp /tmp/shellcheck-stable/shellcheck /usr/local/bin/shellcheck \
    && chmod +x /usr/local/bin/shellcheck \
    && curl -LO "https://github.com/dominikh/go-tools/releases/download/${SC_VERSION}/staticcheck_linux_amd64.tar.gz" \
    && tar -C /tmp -xvf staticcheck_linux_amd64.tar.gz \
    && chmod +x /tmp/staticcheck/staticcheck \
    && cp /tmp/staticcheck/staticcheck /usr/local/bin/staticcheck \
    && rm staticcheck_linux_amd64.tar.gz
curl -L "https://github.com/zricethezav/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks-linux-amd64" -o "/usr/local/bin/gitleaks" \
    && chmod +x /usr/local/bin/gitleaks \
    && curl -L "https://github.com/liamg/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64" -o "/usr/local/bin/tfsec" \
    && chmod +x /usr/local/bin/tfsec \
    && rm shellcheck-stable.linux.x86_64.tar.xz
curl -L "https://github.com/zegl/kube-score/releases/download/v${KUBE_SCORE_VERSION}/kube-score_${KUBE_SCORE_VERSION}_linux_amd64" -o "/usr/local/bin/kube-score" \
    && chmod +x /usr/local/bin/kube-score \
    && wget "https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-bin-${PMD_VERSION}.zip" \
    && unzip -q pmd-bin-${PMD_VERSION}.zip -d /opt/ \
    && mv /opt/pmd-bin-${PMD_VERSION} /opt/pmd-bin \
    && rm pmd-bin-${PMD_VERSION}.zip \
    && curl -L "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" -o "/usr/local/bin/jq" \
    && chmod +x /usr/local/bin/jq
curl -L "https://github.com/arturbosch/detekt/releases/download/${DETEKT_VERSION}/detekt-cli-${DETEKT_VERSION}-all.jar" -o "/usr/local/bin/detekt-cli.jar" \
    && curl -LO "https://github.com/controlplaneio/kubesec/releases/download/v${KUBESEC_VERSION}/kubesec_linux_amd64.tar.gz" \
    && tar -C /usr/local/bin/ -xvf kubesec_linux_amd64.tar.gz \
    && rm kubesec_linux_amd64.tar.gz \
    && curl -LO "https://repo.maven.apache.org/maven2/com/github/spotbugs/spotbugs/${SB_VERSION}/spotbugs-${SB_VERSION}.zip" \
    && unzip -q spotbugs-${SB_VERSION}.zip -d /opt/ \
    && mv /opt/spotbugs-${SB_VERSION} /opt/spotbugs \
    && rm spotbugs-${SB_VERSION}.zip \
    && curl -LO "https://repo1.maven.org/maven2/com/h3xstream/findsecbugs/findsecbugs-plugin/${FSB_VERSION}/findsecbugs-plugin-${FSB_VERSION}.jar" \
    && mv findsecbugs-plugin-${FSB_VERSION}.jar /opt/spotbugs/plugin/findsecbugs-plugin.jar \
    && curl -LO "https://repo1.maven.org/maven2/com/mebigfatguy/fb-contrib/fb-contrib/${FB_CONTRIB_VERSION}/fb-contrib-${FB_CONTRIB_VERSION}.jar" \
    && mv fb-contrib-${FB_CONTRIB_VERSION}.jar /opt/spotbugs/plugin/fb-contrib.jar \
    && curl "https://cdn.shiftleft.io/download/sl" > /usr/local/bin/sl \
    && chmod a+rx /usr/local/bin/sl \
    && mkdir -p /opt/sl-cli && /usr/local/bin/sl update libplugin \
    && /usr/local/bin/sl update go2cpg \
    && /usr/local/bin/sl update csharp2cpg
