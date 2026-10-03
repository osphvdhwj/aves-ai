package io.github.osphvdhwj.aves.ai;
import android.os.Bundle;

import io.github.osphvdhwj.aves.ai.IAvesAiCallback;

interface IAvesAi {
    int getApiVersion();
    List<String> getCapabilities();
    void submit(in Bundle request, IAvesAiCallback cb);
    void cancel(long requestId);
}
