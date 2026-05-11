import { useState } from "react";
import { format } from "date-fns";
import { CalendarIcon, Plus, Wallet, Lock, ArrowRight } from "lucide-react";
import { Link } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { toast } from "sonner";
import { cn } from "@/lib/utils";

const DailyTrips = () => {
  const qc = useQueryClient();
  const [addOpen, setAddOpen] = useState(false);
  const [closeOpen, setCloseOpen] = useState(false);

  // Add daily form
  const [agentId, setAgentId] = useState<string>("");
  const [dailyAmount, setDailyAmount] = useState("");
  const [prepaidAmount, setPrepaidAmount] = useState("");
  const [dailyDate, setDailyDate] = useState<Date>(new Date());

  // Close daily form
  const [selectedDailyId, setSelectedDailyId] = useState<string>("");
  const [totalCollected, setTotalCollected] = useState("");
  const [totalReturns, setTotalReturns] = useState("");

  const { data: agents } = useQuery({
    queryKey: ["delivery_agents_active"],
    queryFn: async () => {
      const { data, error } = await supabase.from("delivery_agents").select("*").eq("is_active", true).order("name");
      if (error) throw error;
      return data;
    },
  });

  const { data: dailies } = useQuery({
    queryKey: ["agent_dailies"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("agent_dailies")
        .select("*, delivery_agents(name)")
        .order("daily_date", { ascending: false });
      if (error) throw error;
      return data as any[];
    },
  });

  const openDailies = (dailies || []).filter((d) => d.status === "open");

  const addMutation = useMutation({
    mutationFn: async () => {
      if (!agentId || !dailyAmount) throw new Error("بيانات ناقصة");
      const { error } = await supabase.from("agent_dailies").insert({
        delivery_agent_id: agentId,
        daily_amount: Number(dailyAmount),
        prepaid_amount: Number(prepaidAmount || 0),
        daily_date: format(dailyDate, "yyyy-MM-dd"),
        status: "open",
      });
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("تمت إضافة اليومية");
      qc.invalidateQueries({ queryKey: ["agent_dailies"] });
      setAddOpen(false);
      setAgentId(""); setDailyAmount(""); setPrepaidAmount(""); setDailyDate(new Date());
    },
    onError: (e: any) => toast.error(e.message),
  });

  const closeMutation = useMutation({
    mutationFn: async () => {
      const daily = openDailies.find((d) => d.id === selectedDailyId);
      if (!daily) throw new Error("اختر يومية");
      const collected = Number(totalCollected || 0);
      const returns = Number(totalReturns || 0);
      // Remaining to collect from agent = collected - returns - prepaid
      const remaining = collected - returns - Number(daily.prepaid_amount || 0);
      const { error } = await supabase
        .from("agent_dailies")
        .update({
          total_collected: collected,
          total_returns: returns,
          remaining_amount: remaining,
          status: "closed",
          closed_at: new Date().toISOString(),
        })
        .eq("id", selectedDailyId);
      if (error) throw error;
      return remaining;
    },
    onSuccess: (remaining) => {
      toast.success(`تم تقفيل اليومية. المتبقي: ${remaining} ج`);
      qc.invalidateQueries({ queryKey: ["agent_dailies"] });
      setCloseOpen(false);
      setSelectedDailyId(""); setTotalCollected(""); setTotalReturns("");
    },
    onError: (e: any) => toast.error(e.message),
  });

  const selectedDaily = openDailies.find((d) => d.id === selectedDailyId);
  const previewRemaining =
    selectedDaily && (totalCollected || totalReturns)
      ? Number(totalCollected || 0) - Number(totalReturns || 0) - Number(selectedDaily.prepaid_amount || 0)
      : null;

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-accent/20 py-8">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-3xl font-bold">اليومية</h1>
          <Link to="/admin">
            <Button variant="outline" size="sm"><ArrowRight className="ml-2 h-4 w-4" />رجوع</Button>
          </Link>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <Card className="hover:shadow-xl transition cursor-pointer" onClick={() => setAddOpen(true)}>
            <CardHeader>
              <div className="w-12 h-12 rounded-lg bg-accent flex items-center justify-center mb-2 text-green-500">
                <Plus className="w-6 h-6" />
              </div>
              <CardTitle>إضافة يومية جديدة</CardTitle>
              <CardDescription>سعر اليومية والدفعة المقدمة والمندوب والتاريخ</CardDescription>
            </CardHeader>
          </Card>

          <Card className="hover:shadow-xl transition cursor-pointer" onClick={() => setCloseOpen(true)}>
            <CardHeader>
              <div className="w-12 h-12 rounded-lg bg-accent flex items-center justify-center mb-2 text-blue-500">
                <Wallet className="w-6 h-6" />
              </div>
              <CardTitle>التحصيل</CardTitle>
              <CardDescription>إدخال المحصل والمرتجع وتقفيل اليومية</CardDescription>
            </CardHeader>
          </Card>
        </div>

        <Card>
          <CardHeader><CardTitle>كل اليوميات</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>التاريخ</TableHead>
                    <TableHead>المندوب</TableHead>
                    <TableHead>سعر اليومية</TableHead>
                    <TableHead>الدفعة</TableHead>
                    <TableHead>المحصل</TableHead>
                    <TableHead>المرتجع</TableHead>
                    <TableHead>المتبقي</TableHead>
                    <TableHead>الحالة</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(dailies || []).map((d) => (
                    <TableRow key={d.id}>
                      <TableCell>{d.daily_date}</TableCell>
                      <TableCell>{d.delivery_agents?.name || "-"}</TableCell>
                      <TableCell>{Number(d.daily_amount).toLocaleString()}</TableCell>
                      <TableCell>{Number(d.prepaid_amount).toLocaleString()}</TableCell>
                      <TableCell>{Number(d.total_collected).toLocaleString()}</TableCell>
                      <TableCell>{Number(d.total_returns).toLocaleString()}</TableCell>
                      <TableCell className="font-bold">{Number(d.remaining_amount).toLocaleString()}</TableCell>
                      <TableCell>
                        {d.status === "closed" ? (
                          <Badge variant="secondary"><Lock className="ml-1 h-3 w-3" />متقفلة</Badge>
                        ) : (
                          <Badge>مفتوحة</Badge>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                  {(!dailies || dailies.length === 0) && (
                    <TableRow><TableCell colSpan={8} className="text-center text-muted-foreground">لا توجد يوميات</TableCell></TableRow>
                  )}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Add Daily Dialog */}
      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>إضافة يومية جديدة</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>المندوب</Label>
              <Select value={agentId} onValueChange={setAgentId}>
                <SelectTrigger><SelectValue placeholder="اختر المندوب" /></SelectTrigger>
                <SelectContent>
                  {(agents || []).map((a) => (
                    <SelectItem key={a.id} value={a.id}>{a.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>سعر اليومية</Label>
              <Input type="number" value={dailyAmount} onChange={(e) => setDailyAmount(e.target.value)} placeholder="مثال: 10000" />
            </div>
            <div>
              <Label>الدفعة المدفوعة (مقدماً)</Label>
              <Input type="number" value={prepaidAmount} onChange={(e) => setPrepaidAmount(e.target.value)} placeholder="مثال: 2000" />
            </div>
            <div>
              <Label>التاريخ</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className={cn("w-full justify-start text-right", !dailyDate && "text-muted-foreground")}>
                    <CalendarIcon className="ml-2 h-4 w-4" />
                    {dailyDate ? format(dailyDate, "yyyy-MM-dd") : "اختر التاريخ"}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar mode="single" selected={dailyDate} onSelect={(d) => d && setDailyDate(d)} initialFocus className={cn("p-3 pointer-events-auto")} />
                </PopoverContent>
              </Popover>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAddOpen(false)}>إلغاء</Button>
            <Button onClick={() => addMutation.mutate()} disabled={addMutation.isPending}>حفظ</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Close Daily Dialog */}
      <Dialog open={closeOpen} onOpenChange={setCloseOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>تحصيل وتقفيل اليومية</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>اختر اليومية (المفتوحة)</Label>
              <Select value={selectedDailyId} onValueChange={setSelectedDailyId}>
                <SelectTrigger><SelectValue placeholder="اختر يومية" /></SelectTrigger>
                <SelectContent>
                  {openDailies.map((d) => (
                    <SelectItem key={d.id} value={d.id}>
                      {d.daily_date} - {d.delivery_agents?.name || "-"} ({Number(d.daily_amount).toLocaleString()} ج)
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            {selectedDaily && (
              <div className="text-sm bg-accent/40 p-3 rounded">
                سعر اليومية: <b>{Number(selectedDaily.daily_amount).toLocaleString()}</b> ج · 
                الدفعة المدفوعة: <b>{Number(selectedDaily.prepaid_amount).toLocaleString()}</b> ج
              </div>
            )}
            <div>
              <Label>إجمالي المبلغ المحصل</Label>
              <Input type="number" value={totalCollected} onChange={(e) => setTotalCollected(e.target.value)} />
            </div>
            <div>
              <Label>إجمالي المبلغ المرتجع</Label>
              <Input type="number" value={totalReturns} onChange={(e) => setTotalReturns(e.target.value)} />
            </div>
            {previewRemaining !== null && (
              <div className="bg-primary/10 p-3 rounded text-center">
                <div className="text-sm text-muted-foreground">المتبقي على المندوب</div>
                <div className="text-2xl font-bold">{previewRemaining.toLocaleString()} ج</div>
                <div className="text-xs text-muted-foreground mt-1">= المحصل - المرتجع - الدفعة المقدمة</div>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCloseOpen(false)}>إلغاء</Button>
            <Button onClick={() => closeMutation.mutate()} disabled={closeMutation.isPending || !selectedDailyId}>
              <Lock className="ml-2 h-4 w-4" />تقفيل اليومية
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default DailyTrips;
